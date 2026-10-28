import XCTest
@testable import MiMiTrends

final class FinnhubWatchlistSelectionTests: XCTestCase {
    func testSelectedOnlyDoesNotReadWatchlistCandidates() throws {
        let entries = [WatchlistEntry(symbol: "MSFT", addedAtMillis: 1)]
        let selection = try FinnhubWatchlistSelection(
            selectedSymbol: " aapl ", includeWatchlist: false, watchlist: entries
        )
        XCTAssertEqual(selection.symbols, ["AAPL"])
    }

    func testWatchlistSelectionIsDeduplicatedBoundedAndOrdered() throws {
        let entries = ["AAPL", "IFX.DE", "MSFT", "NVDA", "AMD", "ORCL", "TSLA"]
            .enumerated().map { WatchlistEntry(symbol: $0.element, addedAtMillis: Int64($0.offset + 1)) }
        let selection = try FinnhubWatchlistSelection(
            selectedSymbol: "AAPL", includeWatchlist: true, watchlist: entries
        )
        XCTAssertEqual(selection.symbols, ["AAPL", "MSFT", "NVDA", "AMD", "ORCL"])
        XCTAssertEqual(selection.symbols.count, FinnhubWatchlistSelection.maximumSymbols)
    }

    func testInvalidSelectedSymbolFailsBeforeOpeningAFeed() {
        XCTAssertThrowsError(try FinnhubWatchlistSelection(
            selectedSymbol: "bad symbol", includeWatchlist: true, watchlist: []
        ))
    }
}
