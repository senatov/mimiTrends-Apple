struct TradeTick: Codable, Equatable, Sendable {
    let symbol: String
    let price: Double
    let timestampMillis: Int64
    let volume: Double
}
