import Charts
import SwiftUI

struct RadarChartPreview: View {
    let symbol: String
    let signal: ScanResult?
    let refreshID: Int

    @State private var bars: [MinuteBar] = []
    @State private var errorMessage: String?
    @State private var isLoading = false

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
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(symbol.isEmpty ? "No symbol selected" : symbol)
                    .font(.title3.weight(.semibold))
                if let signal {
                    Text(signal.price.formatted())
                        .font(.title3.monospacedDigit())
                    Text("\(signal.windowChangePercent.formatted(.number.precision(.fractionLength(2))))%")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(signal.windowChangePercent < 0 ? .red : .green)
                } else if let last = bars.last {
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
            } else if bars.isEmpty {
                ContentUnavailableView(
                    "No saved bars for \(symbol.isEmpty ? "this symbol" : symbol)",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Start a live feed or import a desktop bar snapshot in Chart.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                candleChart
                if bars.contains(where: { $0.volumeStatus.isReliable }) {
                    volumeChart
                }
                if let last = bars.last {
                    Text("\(bars.count) saved bars · latest \(Date(timeIntervalSince1970: TimeInterval(last.minuteEpochSeconds)).formatted(.dateTime.month().day().hour().minute())) · source currency · gaps are not filled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel()
        .task(id: "\(symbol)|\(refreshID)") { await loadBars() }
    }

    private var candleChart: some View {
        Chart(bars, id: \.minuteEpochSeconds) { bar in
            let time = Date(timeIntervalSince1970: TimeInterval(bar.minuteEpochSeconds))
            let rising = bar.close >= bar.open
            RuleMark(
                x: .value("Minute", time),
                yStart: .value("Low", bar.low),
                yEnd: .value("High", bar.high)
            )
            .foregroundStyle(rising ? .green : .red)
            RectangleMark(
                xStart: .value("Start", time.addingTimeInterval(-20)),
                xEnd: .value("End", time.addingTimeInterval(20)),
                yStart: .value("Open", bar.open),
                yEnd: .value("Close", bar.close)
            )
            .foregroundStyle(rising ? .green : .red)
        }
        .chartYScale(domain: priceDomain)
        .frame(height: 235)
        .accessibilityLabel("Saved minute candle chart for \(symbol)")
    }

    private var volumeChart: some View {
        Chart(bars.filter { $0.volumeStatus.isReliable }, id: \.minuteEpochSeconds) { bar in
            BarMark(
                x: .value("Minute", Date(timeIntervalSince1970: TimeInterval(bar.minuteEpochSeconds))),
                y: .value("Reported volume", bar.volume)
            )
            .foregroundStyle(bar.close >= bar.open ? .green.opacity(0.55) : .red.opacity(0.55))
        }
        .frame(height: 75)
        .accessibilityLabel("Reported minute volume for \(symbol)")
    }

    private func loadBars() async {
        let requestedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !requestedSymbol.isEmpty else {
            bars = []
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
                    limit: 60
                )
            }.value
            guard !Task.isCancelled else { return }
            bars = loaded
        } catch {
            guard !Task.isCancelled else { return }
            bars = []
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var priceDomain: ClosedRange<Double> {
        let low = bars.map(\.low).min() ?? 0
        let high = bars.map(\.high).max() ?? 1
        let padding = max((high - low) * 0.08, high * 0.002)
        return max(0, low - padding)...(high + padding)
    }
}
