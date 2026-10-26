import Foundation

struct FinnhubTradeStream: Sendable {
    func run(
        apiKey: String,
        symbol: String,
        onSubscribed: @escaping @Sendable () async -> Void,
        onTrade: @escaping @Sendable (TradeTick) async -> Void
    ) async throws {
        let url = try Self.streamURL(apiKey: apiKey)
        let normalizedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalizedSymbol.isEmpty else { throw FinnhubStreamError.invalidMessage }

        let socket = URLSession.shared.webSocketTask(with: url)
        try await withTaskCancellationHandler {
            socket.resume()
            defer { socket.cancel(with: .normalClosure, reason: nil) }
            do {
                let command = try JSONEncoder().encode(Subscription(type: "subscribe", symbol: normalizedSymbol))
                guard let commandText = String(data: command, encoding: .utf8) else {
                    throw FinnhubStreamError.invalidMessage
                }
                try await socket.send(.string(commandText))
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
                        await onTrade(trade)
                    }
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as FinnhubStreamError {
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

    private struct Subscription: Encodable {
        let type: String
        let symbol: String
    }
}
