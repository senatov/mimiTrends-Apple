import Charts
import SwiftUI

struct RadarChartPlot: View {
    let data: RadarChartData
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Chart {
                ForEach(data.bars, id: \.minuteEpochSeconds) { bar in
                    let time = Date(timeIntervalSince1970: TimeInterval(bar.minuteEpochSeconds))
                    let color: Color = bar.close >= bar.open ? .green : .red
                    RuleMark(
                        x: .value("Minute", time),
                        yStart: .value("Low", bar.low),
                        yEnd: .value("High", bar.high)
                    )
                    .foregroundStyle(color)
                    RectangleMark(
                        xStart: .value("Start", time.addingTimeInterval(-20)),
                        xEnd: .value("End", time.addingTimeInterval(20)),
                        yStart: .value("Open", bar.open),
                        yEnd: .value("Close", bar.close)
                    )
                    .foregroundStyle(color)
                }
                ForEach(data.fastEMA) { point in
                    LineMark(
                        x: .value("Minute", point.date),
                        y: .value("EMA 9", point.value),
                        series: .value("EMA 9 segment", point.segment)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
                ForEach(data.slowEMA) { point in
                    LineMark(
                        x: .value("Minute", point.date),
                        y: .value("EMA 21", point.value),
                        series: .value("EMA 21 segment", point.segment)
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
            }
            .chartYScale(domain: priceDomain)
            .frame(height: 300)
            .accessibilityLabel("Saved minute candle chart with EMA 9 and EMA 21 for \(symbol)")

            HStack(spacing: 14) {
                Label("EMA 9", systemImage: "line.diagonal")
                    .foregroundStyle(.blue)
                Label("EMA 21", systemImage: "line.diagonal")
                    .foregroundStyle(.orange)
            }
            .font(.caption)

            if data.bars.contains(where: { $0.volumeStatus.isReliable }) {
                Chart(data.bars.filter { $0.volumeStatus.isReliable }, id: \.minuteEpochSeconds) { bar in
                    BarMark(
                        x: .value("Minute", Date(timeIntervalSince1970: TimeInterval(bar.minuteEpochSeconds))),
                        y: .value("Reported volume", bar.volume)
                    )
                    .foregroundStyle(bar.close >= bar.open ? .green.opacity(0.55) : .red.opacity(0.55))
                }
                .frame(height: 90)
                .accessibilityLabel("Reported minute volume for \(symbol)")
            }
        }
    }

    private var priceDomain: ClosedRange<Double> {
        let overlayValues = data.fastEMA.map(\.value) + data.slowEMA.map(\.value)
        let low = (data.bars.map(\.low) + overlayValues).min() ?? 0
        let high = (data.bars.map(\.high) + overlayValues).max() ?? 1
        let padding = max((high - low) * 0.08, high * 0.002)
        return max(0, low - padding)...(high + padding)
    }
}
