import Charts
import SwiftUI

struct MarketChartView: View {
    @State private var symbol = "AAPL"
    @State private var selectedRange: ChartRange = .threeHours
    @State private var bars: [MinuteBar] = []
    @State private var loadedSymbol = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Saved market data") {
                    TextField("Symbol", text: $symbol)
                    Picker("Range", selection: $selectedRange) {
                        ForEach(ChartRange.allCases) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    Button("Load chart", systemImage: "arrow.clockwise") {
                        Task { await loadChart() }
                    }
                    .disabled(isLoading || symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if isLoading {
                    ProgressView("Loading saved bars")
                } else if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                } else if bars.isEmpty {
                    ContentUnavailableView(
                        "No saved minute bars",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Start a live feed on Radar and return after completed minutes have been saved.")
                    )
                } else {
                    chartSections
                }
            }
            .navigationTitle("Chart")
            .task { await loadChart() }
        }
    }

    @ViewBuilder
    private var chartSections: some View {
        Section("\(loadedSymbol) · completed minutes") {
            Chart(pricePoints, id: \.bar.minuteEpochSeconds) { point in
                LineMark(
                    x: .value("Time", Date(timeIntervalSince1970: TimeInterval(point.bar.minuteEpochSeconds))),
                    y: .value("Close", point.bar.close),
                    series: .value("Continuous segment", point.segment)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 260)
            .accessibilityLabel("Closing price by minute for \(loadedSymbol)")

            if let last = bars.last {
                LabeledContent("Latest saved close", value: last.close.formatted())
                LabeledContent(
                    "Last completed minute",
                    value: Date(timeIntervalSince1970: TimeInterval(last.minuteEpochSeconds)),
                    format: .dateTime.month().day().hour().minute()
                )
            }
            Text("Prices use the source currency. No currency conversion or historical backfill is applied.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

        let reportedBars = bars.filter { $0.volumeStatus.isReliable }
        if !reportedBars.isEmpty {
            Section("Reported trade volume") {
                Chart(reportedBars, id: \.minuteEpochSeconds) { bar in
                    BarMark(
                        x: .value("Time", Date(timeIntervalSince1970: TimeInterval(bar.minuteEpochSeconds))),
                        y: .value("Volume", bar.volume)
                    )
                    .foregroundStyle(.teal)
                }
                .frame(height: 130)
                .accessibilityLabel("Reported trade volume by minute for \(loadedSymbol)")
            }
        }
        Section {
            Text("Showing \(bars.count) saved bars, at most the latest 360 within \(selectedRange.title). Gaps are missing market data, not zero prices or volume.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var pricePoints: [PricePoint] {
        var segment = 0
        var previousMinute: Int64?
        return bars.map { bar in
            if let previousMinute, bar.minuteEpochSeconds - previousMinute > 60 {
                segment += 1
            }
            previousMinute = bar.minuteEpochSeconds
            return PricePoint(bar: bar, segment: segment)
        }
    }

    private func loadChart() async {
        let requestedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !requestedSymbol.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        let seconds = selectedRange.seconds
        let now = Int64(Date().timeIntervalSince1970)
        do {
            let loaded = try await Task.detached(priority: .userInitiated) {
                let store = try MarketBarStore(url: MarketBarStore.defaultURL())
                return try await store.loadRecentMinuteBars(
                    symbol: requestedSymbol,
                    fromEpochSeconds: now - seconds,
                    throughEpochSeconds: now
                )
            }.value
            bars = loaded
            loadedSymbol = requestedSymbol
        } catch {
            bars = []
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct PricePoint {
    let bar: MinuteBar
    let segment: Int
}

private enum ChartRange: String, CaseIterable, Identifiable {
    case oneHour
    case threeHours
    case twentyFourHours

    var id: Self { self }

    var title: String {
        switch self {
        case .oneHour: "1H"
        case .threeHours: "3H"
        case .twentyFourHours: "24H"
        }
    }

    var seconds: Int64 {
        switch self {
        case .oneHour: 3_600
        case .threeHours: 10_800
        case .twentyFourHours: 86_400
        }
    }
}
