import Foundation

enum RadarSignalSelection {
    static func latestPerSymbol(_ signals: [ScanResult], limit: Int) -> [ScanResult] {
        var seen = Set<String>()
        return Array(signals.sorted { $0.signalEpochMillis > $1.signalEpochMillis }
            .filter { seen.insert($0.symbol).inserted }
            .prefix(max(0, limit)))
    }
}
