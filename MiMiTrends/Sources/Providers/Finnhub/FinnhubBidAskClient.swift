import Foundation

struct FinnhubBidAskClient: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func load(symbol: String, apiKey: String) async throws -> ProviderQuoteSnapshot {
        let request = try Self.request(symbol: symbol, apiKey: apiKey)
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw FinnhubBidAskError.invalidResponse
        }
        if response.statusCode == 401 || response.statusCode == 403 {
            throw FinnhubBidAskError.accessUnavailable
        }
        guard response.statusCode == 200 else { throw FinnhubBidAskError.requestFailed }
        return try Self.decode(data, symbol: symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
    }

    static func request(symbol: String, apiKey: String) throws -> URLRequest {
        let normalized = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard supports(symbol: normalized) else {
            throw FinnhubBidAskError.unsupportedSymbol
        }
        guard !key.isEmpty else { throw FinnhubBidAskError.accessUnavailable }
        guard var components = URLComponents(string: "https://api.finnhub.io/api/v1/stock/bidask") else {
            throw FinnhubBidAskError.invalidResponse
        }
        components.queryItems = [URLQueryItem(name: "symbol", value: normalized)]
        guard let url = components.url else { throw FinnhubBidAskError.invalidResponse }
        var request = URLRequest(url: url)
        request.setValue(key, forHTTPHeaderField: "X-Finnhub-Token")
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    static func supports(symbol: String) -> Bool {
        let normalized = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return normalized.range(of: "^[A-Z][A-Z0-9-]{0,9}$", options: .regularExpression) != nil
    }

    static func decode(_ data: Data, symbol: String) throws -> ProviderQuoteSnapshot {
        let response = try JSONDecoder().decode(BidAskResponse.self, from: data)
        guard let bid = response.bid, let ask = response.ask,
              let observedAtMillis = response.timestamp,
              bid.isFinite, ask.isFinite, bid > 0, ask >= bid,
              observedAtMillis > 0 else {
            throw FinnhubBidAskError.invalidResponse
        }
        return ProviderQuoteSnapshot(
            provider: "FINNHUB", symbol: symbol, identifier: symbol,
            currency: "USD", last: (bid + ask) / 2,
            bid: bid, ask: ask, bidSize: response.bidVolume,
            askSize: response.askVolume, sessionVolume: nil,
            sessionTurnover: nil, averagePrice: nil, executions: nil,
            sessionHigh: nil, sessionLow: nil, previousClose: nil,
            observedAtMillis: observedAtMillis
        )
    }

    private struct BidAskResponse: Decodable {
        let ask: Double?
        let askVolume: Double?
        let bid: Double?
        let bidVolume: Double?
        let timestamp: Int64?

        enum CodingKeys: String, CodingKey {
            case ask = "a", askVolume = "av", bid = "b", bidVolume = "bv", timestamp = "t"
        }
    }
}

enum FinnhubBidAskError: Error {
    case unsupportedSymbol
    case accessUnavailable
    case invalidResponse
    case requestFailed
}
