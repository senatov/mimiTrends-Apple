import XCTest
@testable import MiMiTrends

final class ShortMoveQuoteQualityTests: XCTestCase {
    func testDesktopQuoteQualityFixture() {
        let quote = snapshot(bid: 99.9, ask: 100.1)
        XCTAssertTrue(ShortMoveQuoteQuality.acceptable(quote, marketPrice: 100) { $0 })
        XCTAssertFalse(ShortMoveQuoteQuality.acceptable(
            snapshot(bid: 99, ask: 101), marketPrice: 100
        ) { $0 })
        XCTAssertFalse(ShortMoveQuoteQuality.acceptable(
            snapshot(bid: 103, ask: 103.1), marketPrice: 100
        ) { $0 })
    }

    func testMissingQuoteFieldsAndUnavailableConversion() {
        XCTAssertTrue(ShortMoveQuoteQuality.acceptable(
            snapshot(bid: nil, ask: nil), marketPrice: 100
        ) { $0 })
        XCTAssertTrue(ShortMoveQuoteQuality.acceptable(
            snapshot(bid: 99.9, ask: 100.1), marketPrice: 100
        ) { _ in nil })
        XCTAssertFalse(ShortMoveQuoteQuality.acceptable(
            snapshot(bid: 101, ask: 100), marketPrice: 100
        ) { $0 })
    }

    private func snapshot(bid: Double?, ask: Double?) -> ProviderQuoteSnapshot {
        ProviderQuoteSnapshot(
            provider: "SCALABLE", symbol: "AAPL", identifier: "instrument",
            currency: "USD", last: 100, bid: bid, ask: ask,
            bidSize: nil, askSize: nil, sessionVolume: nil,
            sessionTurnover: nil, averagePrice: nil, executions: nil,
            sessionHigh: nil, sessionLow: nil, previousClose: nil,
            observedAtMillis: 1_000
        )
    }
}
