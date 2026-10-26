enum RapidMoveSignalFactory {
    static func make(
        symbol: String,
        bars: [MinuteBar],
        start: MinuteBar,
        end: MinuteBar,
        eventBarCount: Int,
        changePercent: Double,
        source: String,
        displayPrice: Double,
        nowEpochSeconds: Int64
    ) -> ScanResult {
        let session = bars.filter { $0.minuteEpochSeconds >= nowEpochSeconds - 10_800 }
        return ScanResult(
            symbol: symbol,
            price: displayPrice,
            anomalyScore: 100,
            priceAnomaly: nil,
            volumeAnomaly: nil,
            rangeAnomaly: nil,
            relativeVolume: nil,
            candleBodyRatio: 0,
            windowChangePercent: changePercent,
            windowVolume: session.suffix(eventBarCount).reduce(0) { $0 + $1.volume },
            sessionVolume: session.reduce(0) { $0 + $1.volume },
            sessionTurnover: session.reduce(0) { $0 + $1.close * $1.volume },
            signalAgeMinutes: Int(max(0, nowEpochSeconds - end.minuteEpochSeconds) / 60),
            signalSource: source,
            updatedAtMillis: end.minuteEpochSeconds * 1_000,
            dataStatus: "LIVE",
            signalWindowLabel: "\(max(1, (end.minuteEpochSeconds - start.minuteEpochSeconds) / 60))m",
            signalPrice: start.close,
            signalEpochMillis: end.minuteEpochSeconds * 1_000,
            analysisUpdatedAtMillis: end.minuteEpochSeconds * 1_000,
            scanEvaluatedAtMillis: nowEpochSeconds * 1_000
        )
    }
}
