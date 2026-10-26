struct MinuteBar: Codable, Equatable, Sendable {
    let symbol: String
    let minuteEpochSeconds: Int64
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    let volumeStatus: VolumeStatus

    init(
        symbol: String,
        minuteEpochSeconds: Int64,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        volume: Double,
        volumeStatus: VolumeStatus = .reported
    ) {
        self.symbol = symbol
        self.minuteEpochSeconds = minuteEpochSeconds
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.volumeStatus = volumeStatus
    }

    var isValid: Bool {
        minuteEpochSeconds % 60 == 0 &&
            volume.isFinite && volume >= 0 &&
            (volumeStatus != .reported || volume > 0) &&
            open.isFinite && open > 0 &&
            high.isFinite && low.isFinite && close.isFinite && close > 0 &&
            high >= max(open, close, low) &&
            low <= min(open, close, high)
    }
}
