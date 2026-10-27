struct SustainedMoveSettings: Sendable {
    var movePercent = 0.80
    var windowMinutes: Int64 = 180
    var minimumTurnover = 50_000_000.0
    var minimumPrice = 5.0
}

enum SustainedMoveDetector {
    static func detect(
        symbol: String,
        bars: [MinuteBar],
        nowEpochSeconds: Int64,
        settings: SustainedMoveSettings = SustainedMoveSettings()
    ) -> ScanResult? {
        let recent = bars.filter {
            $0.minuteEpochSeconds >= nowEpochSeconds - settings.windowMinutes * 60 &&
                $0.minuteEpochSeconds <= nowEpochSeconds
        }.sorted { $0.minuteEpochSeconds < $1.minuteEpochSeconds }
        guard let end = recent.last,
              end.minuteEpochSeconds >= nowEpochSeconds - 600,
              end.close >= settings.minimumPrice,
              recent.count >= 20 else { return nil }

        let reported = recent.filter { $0.volumeStatus == .reported && $0.volume > 0 }
        guard reported.count >= 15,
              reported.reduce(0, { $0 + $1.close * $1.volume }) >= settings.minimumTurnover else {
            return nil
        }

        let anchors = recent.dropLast(19).filter {
            end.minuteEpochSeconds - $0.minuteEpochSeconds >= 1_200
        }
        guard let low = anchors.min(by: { $0.close < $1.close }),
              let high = anchors.max(by: { $0.close < $1.close }) else { return nil }
        let rise = (end.close / low.close - 1) * 100
        let drop = (end.close / high.close - 1) * 100
        let rising = rise >= -drop
        let start = rising ? low : high
        let change = rising ? rise : drop
        guard abs(change) >= settings.movePercent else { return nil }

        let eventBars = recent.filter { $0.minuteEpochSeconds >= start.minuteEpochSeconds }
        guard eventBars.count >= 20,
              !zip(eventBars, eventBars.dropFirst()).contains(where: {
                  $0.1.minuteEpochSeconds - $0.0.minuteEpochSeconds > 300
              }) else { return nil }

        return RapidMoveSignalFactory.make(
            symbol: symbol, bars: recent, start: start, end: end,
            eventBarCount: eventBars.count, changePercent: change,
            source: rising ? "Sustained rise" : "Sustained drop",
            displayPrice: end.close, nowEpochSeconds: nowEpochSeconds
        )
    }
}
