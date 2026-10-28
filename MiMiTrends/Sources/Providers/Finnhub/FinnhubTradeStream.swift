import Foundation

struct FinnhubTradeStream: Sendable {
    func run(
        apiKey: String,
        symbols: [String],
        onSubscribed: @escaping @Sendable () async -> Void,
        onTrade: @escaping @Sendable (TradeTick) async throws -> Void
    ) async throws {
        let url = try Self.streamURL(apiKey: apiKey)
        let commands = try Self.subscriptionMessages(for: symbols)
        let subscribedSymbols = Set(symbols)

        let socket = URLSession.shared.webSocketTask(with: url)
        try await withTaskCancellationHandler {
            socket.resume()
            defer { socket.cancel(with: .normalClosure, reason: nil) }
            do {
                for command in commands {
                    try Task.checkCancellation()
                    try await socket.send(.string(command))
                }
                try Task.checkCancellation()
                await onSubscribed()
                while !Task.isCancelled {
                    let message = try await socket.receive()
                    let data: Data
                    switch message {
                    case .data(let payload): data = payload
                    case .string(let text): data = Data(text.utf8)
                    @unknown default: throw FinnhubStreamError.invalidMessage
                    }
                    for trade in try FinnhubTradeDecoder.decode(data) {
                        try Task.checkCancellation()
                        let normalizedSymbol = trade.symbol.uppercased()
                        guard subscribedSymbols.contains(normalizedSymbol) else { continue }
                        try await onTrade(TradeTick(
                            symbol: normalizedSymbol,
                            price: trade.price,
                            timestampMillis: trade.timestampMillis,
                            volume: trade.volume
                        ))
                    }
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as FinnhubStreamError {
                if Task.isCancelled { throw CancellationError() }
                throw error
            } catch let error as MarketBarStoreError {
                if Task.isCancelled { throw CancellationError() }
                throw error
            } catch let error as MarketSignalStoreError {
                if Task.isCancelled { throw CancellationError() }
                throw error
            } catch {
                if Task.isCancelled { throw CancellationError() }
                throw FinnhubStreamError.connectionFailed
            }
        } onCancel: {
            socket.cancel(with: .normalClosure, reason: nil)
        }
    }

    static func streamURL(apiKey: String) throws -> URL {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw FinnhubStreamError.missingKey }
        var components = URLComponents()
        components.scheme = "wss"
        components.host = "ws.finnhub.io"
        components.queryItems = [URLQueryItem(name: "token", value: key)]
        guard let url = components.url else { throw FinnhubStreamError.missingKey }
        return url
    }

    static func subscriptionMessages(for symbols: [String]) throws -> [String] {
        guard (1...FinnhubWatchlistSelection.maximumSymbols).contains(symbols.count),
              Set(symbols).count == symbols.count,
              symbols.allSatisfy({ (try? WatchlistStore.normalize($0)) == $0 }) else {
            throw FinnhubStreamError.invalidSubscription
        }
        return try symbols.map { symbol in
            let data = try JSONEncoder().encode(Subscription(type: "subscribe", symbol: symbol))
            guard let text = String(data: data, encoding: .utf8) else {
                throw FinnhubStreamError.invalidSubscription
            }
            return text
        }
    }

    private struct Subscription: Encodable {
        let type: String
        let symbol: String
    }
}
