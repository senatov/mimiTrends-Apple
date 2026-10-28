import SwiftUI

struct RadarChartPreview: View {
    let symbol: String
    let signal: ScanResult?
    let refreshID: Int

    @State private var allBars: [MinuteBar] = []
    @State private var range: RadarChartRange = .latest
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var chartData: RadarChartData {
        RadarChartData(
            allBars: allBars, range: range,
            nowEpochSeconds: Int64(Date().timeIntervalSince1970)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected alert chart").font(.headline)
                Spacer()
                if let signal {
                    Text(signal.signalSource.replacingOccurrences(of: "_", with: " "))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(signal.windowChangePercent < 0 ? .red : .green)
                }
            }
            Divider()
            HStack {
                Picker("Range", selection: $range) {
                    ForEach(RadarChartRange.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 350)
                Spacer(minLength: 0)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(symbol.isEmpty ? "No symbol selected" : symbol)
                    .font(.title3.weight(.semibold))
                if let signal {
                    Text(signal.price.formatted())
                        .font(.title3.monospacedDigit())
                    Text("\(signal.windowChangePercent.formatted(.number.precision(.fractionLength(2))))%")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(signal.windowChangePercent < 0 ? .red : .green)
                } else if let last = chartData.bars.last {
                    Text(last.close.formatted())
                        .font(.title3.monospacedDigit())
                    Text("latest saved close")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if isLoading {
                ProgressView("Loading saved minute bars")
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else if chartData.bars.isEmpty {
                ContentUnavailableView(
                    "No saved bars in \(range.title)",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Start a live feed, import a desktop snapshot in Chart, or choose Latest for older saved bars.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                RadarChartPlot(data: chartData, symbol: symbol)
                if let last = chartData.bars.last {
                    Text("\(chartData.bars.count) saved bars · latest \(Date(timeIntervalSince1970: TimeInterval(last.minuteEpochSeconds)).formatted(.dateTime.month().day().hour().minute())) · source currency · gaps are not filled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel()
        .task(id: "\(symbol)|\(refreshID)") { await loadBars() }
    }

    private func loadBars() async {
        let requestedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !requestedSymbol.isEmpty else {
            allBars = []
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await Task.detached(priority: .userInitiated) {
                let store = try MarketBarStore(url: MarketBarStore.defaultURL())
                return try await store.loadRecentMinuteBars(
                    symbol: requestedSymbol,
                    fromEpochSeconds: 0,
                    throughEpochSeconds: Int64(Date().timeIntervalSince1970),
                    limit: 360
                )
            }.value
            guard !Task.isCancelled else { return }
            allBars = loaded
        } catch {
            guard !Task.isCancelled else { return }
            allBars = []
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

}
