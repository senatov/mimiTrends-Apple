import Foundation

enum RadarPaneLayout {
    static let handleSize: CGFloat = 14
    static let minimumWideHeight: CGFloat = 460
    static let minimumStackedHeight: CGFloat = 548

    static func wideColumnWidth(totalWidth: CGFloat, ratio: Double) -> CGFloat {
        let available = max(0, totalWidth - handleSize)
        return clamp(available * safeRatio(ratio, fallback: 0.68),
                     minimum: 320, maximum: available - 240)
    }

    static func wideTopHeight(totalHeight: CGFloat, ratio: Double) -> CGFloat {
        let available = max(0, totalHeight - handleSize)
        return clamp(available * safeRatio(ratio, fallback: 0.23),
                     minimum: 145, maximum: available - 280)
    }

    static func stackedSignalHeight(totalHeight: CGFloat, ratio: Double) -> CGFloat {
        let available = max(0, totalHeight - 2 * handleSize)
        return clamp(available * safeRatio(ratio, fallback: 0.22),
                     minimum: 140, maximum: available - 120 - 260)
    }

    static func stackedSourceHeight(
        totalHeight: CGFloat, signalHeight: CGFloat, ratio: Double
    ) -> CGFloat {
        let available = max(0, totalHeight - 2 * handleSize)
        return clamp(available * safeRatio(ratio, fallback: 0.18),
                     minimum: 120, maximum: available - signalHeight - 260)
    }

    static func safeRatio(_ value: Double, fallback: Double) -> CGFloat {
        CGFloat(value.isFinite ? min(max(value, 0), 1) : fallback)
    }

    static func clamp(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        min(max(value, minimum), max(minimum, maximum))
    }
}
