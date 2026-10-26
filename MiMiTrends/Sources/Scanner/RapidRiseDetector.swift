struct RapidRiseSettings: Sendable {
    var risePercent = 0.60
    var riseWindowMinutes: Int64 = 5
    var minimumPrice = 5.0
    var minimumTurnover = 250_000.0
}

enum RapidRiseDetector {
    static func detect(
        symbol: String,
        bars: [MinuteBar],
        nowEpochSeconds: Int64,
        settings: RapidRiseSettings = RapidRiseSettings()
    ) -> ScanResult? {
        let recent = bars.sorted { $0.minuteEpochSeconds < $1.minuteEpochSeconds }
        guard let latest = recent.last,
              latest.minuteEpochSeconds >= nowEpochSeconds - 600 else { return nil }

        var strongest: (start: MinuteBar, end: MinuteBar, change: Double, count: Int)?
        for end in recent where end.minuteEpochSeconds >= nowEpochSeconds - 900 {
            guard end.volumeStatus == .reported, end.volume > 0 else { continue }
            let window = recent.filter {
                $0.minuteEpochSeconds >= end.minuteEpochSeconds - settings.riseWindowMinutes * 60 &&
                    $0.minuteEpochSeconds < end.minuteEpochSeconds
            }
            guard let start = window.min(by: { $0.close < $1.close }) else { continue }
            let change = (end.close / start.close - 1) * 100
            guard change >= settings.risePercent - 1e-9 else { continue }
            let eventBars = recent.filter {
                $0.minuteEpochSeconds >= start.minuteEpochSeconds &&
                    $0.minuteEpochSeconds <= end.minuteEpochSeconds
            }
            guard hasReliableActivity(recent, eventBars: eventBars, end: end, settings: settings) else { continue }
            if let current = strongest,
               change < current.change || (change == current.change && end.minuteEpochSeconds <= current.end.minuteEpochSeconds) {
                continue
            }
            strongest = (start, end, change, eventBars.count)
        }
        guard let move = strongest else { return nil }
        let session = recent.filter { $0.minuteEpochSeconds >= nowEpochSeconds - 10_800 }
        return ScanResult(
            symbol: symbol, price: latest.close, anomalyScore: 100,
            priceAnomaly: nil, volumeAnomaly: nil, rangeAnomaly: nil,
            relativeVolume: nil, candleBodyRatio: 0,
            windowChangePercent: move.change,
            windowVolume: session.suffix(move.count).reduce(0) { $0 + $1.volume },
            sessionVolume: session.reduce(0) { $0 + $1.volume },
            sessionTurnover: session.reduce(0) { $0 + $1.close * $1.volume },
            signalAgeMinutes: Int(max(0, nowEpochSeconds - move.end.minuteEpochSeconds) / 60),
            signalSource: "Rapid rise",
            updatedAtMillis: move.end.minuteEpochSeconds * 1_000,
            dataStatus: "LIVE",
            signalWindowLabel: "\(max(1, (move.end.minuteEpochSeconds - move.start.minuteEpochSeconds) / 60))m",
            signalPrice: move.start.close,
            signalEpochMillis: move.end.minuteEpochSeconds * 1_000,
            analysisUpdatedAtMillis: move.end.minuteEpochSeconds * 1_000,
            scanEvaluatedAtMillis: nowEpochSeconds * 1_000
        )
    }

    private static func hasReliableActivity(
        _ bars: [MinuteBar], eventBars: [MinuteBar], end: MinuteBar, settings: RapidRiseSettings
    ) -> Bool {
        guard end.close >= settings.minimumPrice, eventBars.count >= 2,
              !zip(eventBars, eventBars.dropFirst()).contains(where: { pair in
                  pair.1.minuteEpochSeconds - pair.0.minuteEpochSeconds > 180
              }),
              eventBars.filter({ $0.volumeStatus == .reported && $0.volume > 0 }).count >= 2 else {
            return false
        }
        let active = bars.filter {
            $0.minuteEpochSeconds >= end.minuteEpochSeconds - 1_800 &&
                $0.minuteEpochSeconds <= end.minuteEpochSeconds &&
                $0.volumeStatus == .reported && $0.volume > 0
        }
        return active.count >= 3 &&
            active.reduce(0) { $0 + $1.close * $1.volume } >= settings.minimumTurnover
    }
}
