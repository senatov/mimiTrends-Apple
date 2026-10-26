import XCTest
@testable import MiMiTrends

@MainActor
final class RadarSessionTests: XCTestCase {
    func testStoppingCancelsAnActiveScan() async {
        let session = RadarSession()
        let started = expectation(description: "Scan started")
        let cancelled = expectation(description: "Scan cancelled")

        XCTAssertFalse(session.isScanning)
        session.start { _ in
            started.fulfill()
            do {
                try await Task.sleep(for: .seconds(60))
            } catch {
                cancelled.fulfill()
            }
        }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertTrue(session.isScanning)

        session.stop()
        await fulfillment(of: [cancelled], timeout: 2)
        XCTAssertFalse(session.isScanning)
    }

    func testLateTradeAfterStopIsIgnored() {
        let session = RadarSession()
        let id = session.start { _ in
            try? await Task.sleep(for: .seconds(60))
        }
        session.record(TradeTick(symbol: "AAPL", price: 100, timestampMillis: 1_000, volume: 2), runID: id)
        XCTAssertEqual(session.tradeCount, 1)

        session.stop()
        session.record(TradeTick(symbol: "AAPL", price: 101, timestampMillis: 2_000, volume: 3), runID: id)
        XCTAssertEqual(session.tradeCount, 1)
        XCTAssertEqual(session.lastTrade?.price, 100)
    }

    func testOldFeedCannotUpdateNewFeed() {
        let session = RadarSession()
        let oldID = session.start { _ in
            try? await Task.sleep(for: .seconds(60))
        }
        let newID = session.start { _ in
            try? await Task.sleep(for: .seconds(60))
        }
        session.markSubscribed(runID: oldID)
        XCTAssertFalse(session.isSubscribed)
        session.markSubscribed(runID: newID)
        XCTAssertTrue(session.isSubscribed)
        session.record(TradeTick(symbol: "AAPL", price: 100, timestampMillis: 1_000, volume: 2), runID: oldID)
        XCTAssertEqual(session.tradeCount, 0)
        session.record(TradeTick(symbol: "MSFT", price: 200, timestampMillis: 2_000, volume: 3), runID: newID)
        XCTAssertEqual(session.lastTrade?.symbol, "MSFT")
        XCTAssertEqual(session.tradeCount, 1)
        session.stop()
        XCTAssertFalse(session.isSubscribed)
    }
}
