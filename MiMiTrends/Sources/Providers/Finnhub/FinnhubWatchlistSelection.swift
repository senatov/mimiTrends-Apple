import Foundation

struct FinnhubWatchlistSelection: Sendable {
    static let maximumSymbols = 5

    let symbols: [String]

    init(selectedSymbol: String, includeWatchlist: Bool, watchlist: [WatchlistEntry]) throws {
        let selected = try WatchlistStore.normalize(selectedSymbol)
        var result = [selected]
        if includeWatchlist {
            for entry in watchlist where result.count < Self.maximumSymbols {
                let candidate = entry.symbol
                guard FinnhubBidAskClient.supports(symbol: candidate),
                      !result.contains(candidate) else { continue }
                result.append(candidate)
            }
        }
        symbols = result
    }
}
