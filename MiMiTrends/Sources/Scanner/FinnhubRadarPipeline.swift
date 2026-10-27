import Foundation

struct FinnhubRadarPipeline: Sendable {
    private let aggregator = FinnhubMinuteAggregator()
    private let store: MarketBarStore
    private let signalStore: MarketSignalStore

    init(databaseURL: URL) throws {
        store = try MarketBarStore(url: databaseURL)
        signalStore = try MarketSignalStore(url: databaseURL.deletingLastPathComponent()
            .appendingPathComponent("mimitrends-signals.db"))
    }

    init() throws {
        try self.init(databaseURL: MarketBarStore.defaultURL())
    }

    func accept(
        _ trade: TradeTick,
        nowEpochSeconds: Int64,
        quote: ProviderQuoteSnapshot? = nil,
        marketCurrency: String? = nil
    ) async throws -> Update {
        try Task.checkCancellation()
        guard let bar = await aggregator.accept(trade) else {
            return Update(storedBar: false, signal: nil, storedSignal: false)
        }
        try Task.checkCancellation()
        let stored = try await store.upsert(bar)
        let recent = try await store.loadMinuteBars(
            symbol: trade.symbol, fromEpochSeconds: nowEpochSeconds - 10_800
        )
        let candidate = RapidCrashDetector.detect(
            symbol: trade.symbol, bars: recent, nowEpochSeconds: nowEpochSeconds
        ) ?? RapidRiseDetector.detect(
            symbol: trade.symbol, bars: recent, nowEpochSeconds: nowEpochSeconds
        ) ?? SustainedMoveDetector.detect(
            symbol: trade.symbol, bars: recent, nowEpochSeconds: nowEpochSeconds
        ) ?? TradableCorridorDetector.detect(
            symbol: trade.symbol, bars: recent, nowEpochSeconds: nowEpochSeconds
        )
        var signal = candidate
        if let quote, let candidate,
           quote.symbol.caseInsensitiveCompare(trade.symbol) == .orderedSame,
           quote.observedAtMillis <= nowEpochSeconds * 1_000,
           quote.observedAtMillis >= nowEpochSeconds * 1_000 - 120_000 {
            let acceptable = ShortMoveQuoteQuality.acceptable(
                quote, marketPrice: recent.last?.close ?? candidate.price
            ) { midpoint in
                quote.currency.caseInsensitiveCompare(marketCurrency ?? "") == .orderedSame ? midpoint : nil
            }
            if !acceptable { signal = nil }
        }
        let storedSignal: Bool
        if let signal {
            storedSignal = try await signalStore.record(signal)
        } else {
            storedSignal = false
        }
        return Update(storedBar: stored, signal: signal, storedSignal: storedSignal)
    }

    struct Update: Sendable {
        let storedBar: Bool
        let signal: ScanResult?
        let storedSignal: Bool
    }
}
