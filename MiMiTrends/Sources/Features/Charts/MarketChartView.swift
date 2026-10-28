import SwiftUI
import UniformTypeIdentifiers

struct MarketChartView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var symbol = "AAPL"
    @State private var selectedRange: RadarChartRange = .threeHours
    @State private var loadedRange: RadarChartRange = .threeHours
    @State private var bars: [MinuteBar] = []
    @State private var loadedSymbol = ""
    @State private var isLoading = false
    @State private var isImporting = false
    @State private var showingImporter = false
    @State private var importMessage: String?
    @State private var errorMessage: String?
    @State private var loadRequestID = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    controls
                    chartPanel
                }
                .padding(14)
                .frame(maxWidth: 1_400)
                .frame(maxWidth: .infinity)
            }
            .background(TrendsColors.canvas(colorScheme))
            .navigationTitle("Chart")
            .task { await loadChart() }
            .onChange(of: selectedRange) { _, _ in Task { await loadChart() } }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [UTType(filenameExtension: "sqlite") ?? .data]
            ) { result in
                if case .success(let url) = result {
                    Task { await importSnapshot(at: url) }
                } else if case .failure(let error) = result {
                    importMessage = error.localizedDescription
                }
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved market data").font(.headline)
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) { actionControls }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { actionControls }
                    VStack(alignment: .leading, spacing: 10) { actionControls }
                }
            }
            Picker("Range", selection: $selectedRange) {
                ForEach(RadarChartRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 350)
            if isImporting { ProgressView("Importing minute bars") }
            if let importMessage {
                Text(importMessage).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel()
    }

    @ViewBuilder
    private var actionControls: some View {
        TextField("Ticker symbol", text: $symbol)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .frame(maxWidth: 240)
            .onSubmit { Task { await loadChart() } }
        TrendsActionButton(title: "Load chart", systemImage: "arrow.clockwise") {
            Task { await loadChart() }
        }
        .disabled(isLoading || symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        TrendsActionButton(
            title: "Import desktop snapshot",
            systemImage: "square.and.arrow.down",
            tint: .teal
        ) { showingImporter = true }
        .disabled(isImporting)
    }

    private var chartPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed minute chart").font(.headline)
            Divider()
            if isLoading {
                ProgressView("Loading saved bars")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if bars.isEmpty {
                ContentUnavailableView(
                    "No saved minute bars",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Start a live feed on Radar or import a desktop snapshot, then load the chart.")
                )
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                chartContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel()
    }

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(loadedSymbol).font(.title3.weight(.semibold))
                if let last = bars.last {
                    Text(last.close.formatted())
                        .font(.title3.monospacedDigit())
                    Text("latest saved close")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            RadarChartPlot(
                data: RadarChartData(
                    allBars: bars, range: .latest,
                    nowEpochSeconds: Int64(Date().timeIntervalSince1970),
                    latestLimit: 360
                ),
                symbol: loadedSymbol
            )
            if let last = bars.last {
                Text("\(bars.count) saved bars in \(loadedRange.title) · latest \(Date(timeIntervalSince1970: TimeInterval(last.minuteEpochSeconds)).formatted(.dateTime.month().day().hour().minute())) · source currency · gaps are not filled")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private func loadChart() async {
        let requestedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !requestedSymbol.isEmpty else { return }
        loadRequestID += 1
        let requestID = loadRequestID
        let requestedRange = selectedRange
        isLoading = true
        errorMessage = nil
        let seconds = requestedRange.seconds
        let now = Int64(Date().timeIntervalSince1970)
        do {
            let loaded = try await Task.detached(priority: .userInitiated) {
                let store = try MarketBarStore(url: MarketBarStore.defaultURL())
                return try await store.loadRecentMinuteBars(
                    symbol: requestedSymbol,
                    fromEpochSeconds: seconds.map { now - $0 } ?? 0,
                    throughEpochSeconds: now
                )
            }.value
            guard !Task.isCancelled, requestID == loadRequestID else { return }
            bars = loaded
            loadedSymbol = requestedSymbol
            loadedRange = requestedRange
        } catch {
            guard !Task.isCancelled, requestID == loadRequestID else { return }
            bars = []
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func importSnapshot(at url: URL) async {
        isImporting = true
        importMessage = nil
        do {
            let summary = try await DesktopBarSnapshotImporter.importSnapshot(
                at: url, into: MarketBarStore.defaultURL()
            )
            symbol = summary.symbol
            selectedRange = .latest
            importMessage = "Imported \(summary.barCount) bars for \(summary.symbol); \(summary.changedCount) saved or updated."
            await loadChart()
        } catch {
            importMessage = error.localizedDescription
        }
        isImporting = false
    }
}
