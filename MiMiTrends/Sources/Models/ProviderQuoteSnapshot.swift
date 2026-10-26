struct ProviderQuoteSnapshot: Codable, Equatable, Sendable {
    let provider: String
    let symbol: String
    let identifier: String
    let currency: String
    let last: Double
    let bid: Double?
    let ask: Double?
    let bidSize: Double?
    let askSize: Double?
    let sessionVolume: Double?
    let sessionTurnover: Double?
    let averagePrice: Double?
    let executions: Int64?
    let sessionHigh: Double?
    let sessionLow: Double?
    let previousClose: Double?
    let observedAtMillis: Int64
}
