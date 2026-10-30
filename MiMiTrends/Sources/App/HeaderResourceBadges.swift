#if os(macOS)
import Observation
import SwiftUI

@MainActor
@Observable
private final class HeaderResourceHistory {
    private(set) var memory: [Double] = []
    private(set) var threads: [Double] = []
    private(set) var footprintBytes: UInt64 = 0
    private(set) var compressedBytes: UInt64 = 0
    private(set) var threadCount = 0

    func record(_ sample: ProcessResourceSample) {
        footprintBytes = sample.footprintBytes
        compressedBytes = sample.compressedBytes
        threadCount = sample.threadCount
        memory = Array((memory + [Double(sample.footprintBytes) / 1_048_576]).suffix(24))
        threads = Array((threads + [Double(sample.threadCount)]).suffix(24))
    }
}

struct HeaderResourceBadges: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var history = HeaderResourceHistory()

    var body: some View {
        HStack(spacing: 8) {
            metric(
                title: "MEMORY",
                value: history.footprintBytes == 0 ? "— MB" : "\(Int((history.footprintBytes + 524_288) / 1_048_576)) MB",
                color: .blue,
                values: history.memory
            )
            .help("App memory footprint; compressed \(Int((history.compressedBytes + 524_288) / 1_048_576)) MB")
            .accessibilityLabel("App memory footprint \(history.footprintBytes == 0 ? "unavailable" : "\(Int((history.footprintBytes + 524_288) / 1_048_576)) megabytes")")

            Rectangle()
                .fill(.primary.opacity(0.12))
                .frame(width: 1, height: 22)
                .accessibilityHidden(true)

            metric(
                title: "THREADS",
                value: history.threadCount == 0 ? "—" : "\(history.threadCount)",
                color: .indigo,
                values: history.threads
            )
            .help("Threads in this app process")
            .accessibilityLabel("Threads in this app process \(history.threadCount)")
        }
        .padding(.horizontal, 10)
        .headerBadgeSurface()
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                let sample = await Task.detached(priority: .utility) {
                    ProcessResourceSampler.capture()
                }.value
                history.record(sample)
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    private func metric(title: String, value: String, color: Color, values: [Double]) -> some View {
        HStack(spacing: 7) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.light))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.light).monospaced())
                    .monospacedDigit()
                    .foregroundStyle(color)
            }
            HeaderResourceSparkline(values: values, color: color)
                .frame(width: 44, height: 20)
        }
    }
}

private struct HeaderResourceSparkline: View {
    let values: [Double]
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard !values.isEmpty else { return }
            let minimum = max(0, (values.min() ?? 0) - 3)
            let maximum = max((values.max() ?? 0) + 3, minimum + 6)
            let points = values.enumerated().map { index, value in
                CGPoint(
                    x: 2 + (size.width - 4) * CGFloat(index) / CGFloat(max(values.count - 1, 1)),
                    y: size.height - 2 - (size.height - 4) * CGFloat((value - minimum) / (maximum - minimum))
                )
            }
            var line = Path()
            line.addLines(points)
            context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
            if let last = points.last {
                context.fill(Path(ellipseIn: CGRect(x: last.x - 1.8, y: last.y - 1.8, width: 3.6, height: 3.6)), with: .color(color))
            }
        }
        .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 4))
        .accessibilityHidden(true)
    }
}
#endif
