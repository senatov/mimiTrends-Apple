import XCTest
@testable import MiMiTrends

final class MarketRadarScannerTests: XCTestCase {
    func testInterleavesDistinctSymbolsFromBothDiscoverySources() {
        XCTAssertEqual(
            MarketRadarScanner.interleave(["AAPL", "MSFT", "NVDA"], ["NVDA", "TSLA", "AMD"], limit: 5),
            ["AAPL", "NVDA", "MSFT", "TSLA", "AMD"]
        )
    }

    func testYahooMostActiveSelectionRequiresEquitiesWithVolume() {
        let quotes: [[String: Any]] = [
            ["symbol": "LOW", "quoteType": "EQUITY", "regularMarketVolume": 10],
            ["symbol": "HIGH", "quoteType": "EQUITY", "regularMarketVolume": 100],
            ["symbol": "FUND", "quoteType": "ETF", "regularMarketVolume": 1_000],
            ["symbol": "ZERO", "quoteType": "EQUITY", "regularMarketVolume": 0],
            ["symbol": "HIGH", "quoteType": "EQUITY", "regularMarketVolume": 100]
        ]
        XCTAssertEqual(YahooRadarSource.activeSymbols(in: quotes, limit: 3), ["HIGH", "LOW"])
    }

    func testYahooBarDecoderSkipsIncompleteCandles() throws {
        let root: [String: Any] = ["chart": ["result": [[
            "timestamp": [120, 180],
            "indicators": ["quote": [[
                "open": [10.0, NSNull()], "high": [11.0, 11.0],
                "low": [9.0, 9.0], "close": [10.5, 10.5],
                "volume": [100, 0]
            ]]]
        ]]]]
        let bars = try YahooRadarSource.decodeBars(root, symbol: "AAPL")
        XCTAssertEqual(bars.count, 1)
        XCTAssertEqual(bars.first?.minuteEpochSeconds, 120)
    }

    func testTraderFoxFiltersStaleAndInactiveRows() throws {
        let now: Int64 = 1_800_000_000
        let html = """
        <script>var equities = {
          "1":{"active":"Y","currency":"USD","symbol":"AAPL","v":200,"p":2.5,"t":1800000000},
          "2":{"active":"N","currency":"USD","symbol":"OFF","v":20,"p":7,"t":1800000000},
          "3":{"active":"Y","currency":"USD","symbol":"OLD","v":20,"p":8,"t":1700000000}
        };</script>
        """
        XCTAssertEqual(try TraderFoxRadarSource.decode(html, limit: 10, nowSeconds: now), ["AAPL"])
    }
}
