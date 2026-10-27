import Foundation

actor FinnhubBidAskSampler {
    private let load: @Sendable (String, String) async throws -> ProviderQuoteSnapshot
    private var lastAttemptAtMillis: Int64 = 0
    private var accessUnavailable = false
    private var cached: ProviderQuoteSnapshot?

    init(load: @escaping @Sendable (String, String) async throws -> ProviderQuoteSnapshot = {
        try await FinnhubBidAskClient().load(symbol: $0, apiKey: $1)
    }) {
        self.load = load
    }

    func latest(symbol: String, apiKey: String, nowMillis: Int64) async -> ProviderQuoteSnapshot? {
        guard FinnhubBidAskClient.supports(symbol: symbol), !accessUnavailable else { return nil }
        if lastAttemptAtMillis == 0 || nowMillis - lastAttemptAtMillis >= 60_000 {
            lastAttemptAtMillis = nowMillis
            do {
                let quote = try await load(symbol, apiKey)
                try Task.checkCancellation()
                cached = quote
            } catch FinnhubBidAskError.accessUnavailable {
                accessUnavailable = true
                cached = nil
            } catch {
                cached = nil
            }
        }
        guard let cached,
              cached.observedAtMillis <= nowMillis,
              cached.observedAtMillis >= nowMillis - 120_000 else { return nil }
        return cached
    }
}
