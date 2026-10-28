import XCTest
@testable import MiMiTrends

final class FinnhubMinuteAggregatorTests: XCTestCase {
    func testCompletedMinuteMatchesDesktopAggregatorFixture() async {
        let aggregator = FinnhubMinuteAggregator()
        let ticks = [
            TradeTick(symbol: "AAPL", price: 100, timestampMillis: 60_001, volume: 5),
            TradeTick(symbol: "AAPL", price: 102, timestampMillis: 75_000, volume: 7),
            TradeTick(symbol: "AAPL", price: 99, timestampMillis: 80_000, volume: 3)
        ]
        for tick in ticks {
            let completed = await aggregator.accept(tick)
            XCTAssertNil(completed)
        }
        let completed = await aggregator.accept(
            TradeTick(symbol: "AAPL", price: 101, timestampMillis: 120_001, volume: 2)
        )
        XCTAssertEqual(completed?.minuteEpochSeconds, 60)
        XCTAssertEqual(completed?.open, 100)
        XCTAssertEqual(completed?.high, 102)
        XCTAssertEqual(completed?.low, 99)
        XCTAssertEqual(completed?.close, 99)
        XCTAssertEqual(completed?.volume, 15)
        XCTAssertEqual(completed?.volumeStatus, .reported)
    }

    func testZeroVolumeIsNotReported() async {
        let aggregator = FinnhubMinuteAggregator()
        _ = await aggregator.accept(TradeTick(symbol: "AAPL", price: 100, timestampMillis: 60_001, volume: -1))
        let completed = await aggregator.accept(
            TradeTick(symbol: "AAPL", price: 101, timestampMillis: 120_001, volume: 0)
        )
        XCTAssertEqual(completed?.volume, 0)
        XCTAssertEqual(completed?.volumeStatus, .zero)
    }

    func testInterleavedSymbolsKeepSeparateOpenMinutes() async {
        let aggregator = FinnhubMinuteAggregator()
        _ = await aggregator.accept(TradeTick(symbol: "AAPL", price: 100, timestampMillis: 60_000, volume: 2))
        _ = await aggregator.accept(TradeTick(symbol: "MSFT", price: 200, timestampMillis: 60_000, volume: 3))
        _ = await aggregator.accept(TradeTick(symbol: "AAPL", price: 101, timestampMillis: 80_000, volume: 4))
        let microsoft = await aggregator.accept(
            TradeTick(symbol: "MSFT", price: 201, timestampMillis: 120_000, volume: 5)
        )
        let apple = await aggregator.accept(
            TradeTick(symbol: "AAPL", price: 102, timestampMillis: 120_000, volume: 6)
        )
        XCTAssertEqual(microsoft?.symbol, "MSFT")
        XCTAssertEqual(microsoft?.open, 200)
        XCTAssertEqual(microsoft?.volume, 3)
        XCTAssertEqual(apple?.symbol, "AAPL")
        XCTAssertEqual(apple?.close, 101)
        XCTAssertEqual(apple?.volume, 6)
    }
}
