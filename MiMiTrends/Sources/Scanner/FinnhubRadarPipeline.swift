import Foundation

struct FinnhubRadarPipeline: Sendable {
    private let aggregator = FinnhubMinuteAggregator()
    private let store: MarketBarStore

    init(databaseURL: URL) throws {
        store = try MarketBarStore(url: databaseURL)
    }

    init() throws {
        try self.init(databaseURL: MarketBarStore.defaultURL())
    }

    func accept(_ trade: TradeTick, nowEpochSeconds: Int64) async throws -> Update {
        guard let bar = await aggregator.accept(trade) else {
            return Update(storedBar: false, signal: nil)
        }
        try Task.checkCancellation()
        let stored = try await store.upsert(bar)
        let recent = try await store.loadMinuteBars(
            symbol: trade.symbol, fromEpochSeconds: nowEpochSeconds - 10_800
        )
        let signal = RapidCrashDetector.detect(
            symbol: trade.symbol, bars: recent, nowEpochSeconds: nowEpochSeconds
        ) ?? RapidRiseDetector.detect(
            symbol: trade.symbol, bars: recent, nowEpochSeconds: nowEpochSeconds
        ) ?? SustainedMoveDetector.detect(
            symbol: trade.symbol, bars: recent, nowEpochSeconds: nowEpochSeconds
        )
        return Update(storedBar: stored, signal: signal)
    }

    struct Update: Sendable {
        let storedBar: Bool
        let signal: ScanResult?
    }
}
