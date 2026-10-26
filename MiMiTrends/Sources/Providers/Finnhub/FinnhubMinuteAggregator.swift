actor FinnhubMinuteAggregator {
    private var openBars: [String: MinuteBar] = [:]

    func accept(_ tick: TradeTick) -> MinuteBar? {
        let minute = tick.timestampMillis / 60_000 * 60
        let volume = max(0, tick.volume)
        let previous = openBars[tick.symbol]

        guard let previous, previous.minuteEpochSeconds == minute else {
            openBars[tick.symbol] = MinuteBar(
                symbol: tick.symbol, minuteEpochSeconds: minute,
                open: tick.price, high: tick.price, low: tick.price,
                close: tick.price, volume: volume,
                volumeStatus: volume > 0 ? .reported : .zero
            )
            return previous
        }

        let totalVolume = previous.volume + volume
        openBars[tick.symbol] = MinuteBar(
            symbol: tick.symbol, minuteEpochSeconds: minute,
            open: previous.open, high: max(previous.high, tick.price),
            low: min(previous.low, tick.price), close: tick.price,
            volume: totalVolume,
            volumeStatus: totalVolume > 0 ? .reported : .zero
        )
        return nil
    }
}
