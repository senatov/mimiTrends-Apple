struct ProviderInstrument: Codable, Equatable, Sendable {
    let provider: String
    let symbol: String
    let identifier: String
    let mic: String
    let currency: String
    let resolvedName: String
    let updatedAtMillis: Int64
}
