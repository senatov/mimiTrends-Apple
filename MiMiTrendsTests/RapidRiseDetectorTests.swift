import XCTest
@testable import MiMiTrends

final class RapidRiseDetectorTests: XCTestCase {
    func testDesktopRiseFixtureSelectsCloseConfirmedPeak() throws {
        let now: Int64 = 13_000
        let bars = prices("RISE", endingAt: now, [100, 100.1, 101.8, 100.4])
        let signal = try XCTUnwrap(RapidRiseDetector.detect(symbol: "RISE", bars: bars, nowEpochSeconds: now))
        XCTAssertEqual(signal.windowChangePercent, 1.8, accuracy: 1e-9)
        XCTAssertEqual(signal.signalEpochMillis, (now - 60) * 1_000)
        XCTAssertEqual(signal.signalPrice, 100)
        XCTAssertEqual(signal.price, 100.4)
        XCTAssertEqual(signal.signalSource, "Rapid rise")
        XCTAssertNil(signal.priceAnomaly)
        XCTAssertNil(signal.rangeAnomaly)
        XCTAssertNoThrow(try JSONEncoder().encode(signal))
    }

    func testThinMissingAndStaleBarsDoNotSignal() {
        let now: Int64 = 13_000
        let thin = prices("THIN", endingAt: now, [100, 100.1, 101.8, 100.4], volume: 1)
        let missing = prices("MISSING", endingAt: now, [100, 100.1, 101.8, 100.4], status: .missing)
        let stale = prices("STALE", endingAt: now - 660, [100, 100.1, 101.8, 100.4])
        XCTAssertNil(RapidRiseDetector.detect(symbol: "THIN", bars: thin, nowEpochSeconds: now))
        XCTAssertNil(RapidRiseDetector.detect(symbol: "MISSING", bars: missing, nowEpochSeconds: now))
        XCTAssertNil(RapidRiseDetector.detect(symbol: "STALE", bars: stale, nowEpochSeconds: now))
    }

    private func prices(
        _ symbol: String, endingAt end: Int64, _ closes: [Double],
        volume: Double = 1_000, status: VolumeStatus = .reported
    ) -> [MinuteBar] {
        closes.enumerated().map { index, close in
            MinuteBar(
                symbol: symbol, minuteEpochSeconds: end - Int64(closes.count - 1 - index) * 60,
                open: close, high: close, low: close, close: close,
                volume: volume, volumeStatus: status
            )
        }
    }
}
