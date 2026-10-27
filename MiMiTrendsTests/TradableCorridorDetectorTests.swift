import Foundation
import XCTest
@testable import MiMiTrends

final class TradableCorridorDetectorTests: XCTestCase {
    private let pattern = [99.0, 99.3, 99.8, 100.4, 100.9, 101.0,
                           100.7, 100.2, 99.7, 99.2, 99.0, 99.1]

    func testDesktopStableCorridorFixture() throws {
        let now: Int64 = 100_000
        let bars = patternBars(endingAt: now, count: 72)
        let result = try XCTUnwrap(TradableCorridorDetector.detect(
            symbol: "NVDA", bars: bars, nowEpochSeconds: now
        ))

        XCTAssertEqual(result.signalSource, "Tradable corridor")
        XCTAssertEqual(result.signalWindowLabel, "120m corridor")
        XCTAssertGreaterThanOrEqual(result.anomalyScore, 60)
        XCTAssertGreaterThan(result.windowChangePercent, 1)
        XCTAssertEqual(result.windowChangePercent,
                       (result.price / result.signalPrice - 1) * 100, accuracy: 1e-12)
    }

    func testOneWayTrendAndSparseWindowAreRejected() {
        let now: Int64 = 200_000
        let trend = (0..<72).map { index in
            bar(now - Int64(71 - index) * 60, 90 + Double(index) * 0.12)
        }
        let sparse = (0..<72).map { index in
            bar(now - Int64(71 - index) * 600, [99.0, 100, 101, 100][index % 4])
        }

        XCTAssertNil(TradableCorridorDetector.detect(symbol: "TREND", bars: trend, nowEpochSeconds: now))
        XCTAssertNil(TradableCorridorDetector.detect(symbol: "NVDA", bars: sparse, nowEpochSeconds: now))
    }

    func testBrokenLowerEdgeAndRepeatedRecentBreaksAreRejected() {
        let now: Int64 = 300_000
        let broken = patternBars(endingAt: now - 60, count: 71) + [bar(now, 97.5)]
        XCTAssertNil(TradableCorridorDetector.detect(symbol: "NVDA", bars: broken, nowEpochSeconds: now))

        let closes = (0..<72).map { pattern[$0 % pattern.count] }
        var repeated = closes
        repeated[67] = 97.5
        repeated[69] = 97.6
        repeated[71] = 99.1
        let bars = repeated.enumerated().map { index, close in
            bar(now - Int64(71 - index) * 60, close)
        }
        XCTAssertNil(TradableCorridorDetector.detect(symbol: "NVDA", bars: bars, nowEpochSeconds: now))
    }

    func testUpsideSpikesDoNotLiftCorridorUpperEdge() throws {
        let now: Int64 = 500_000
        let spiked = [99.0, 99.3, 99.8, 100.4, 100.9, 101.0,
                       100.7, 100.2, 99.7, 99.2, 99.0, 102.0]
        let bars = (0..<73).map { index in
            bar(now - Int64(72 - index) * 60, spiked[index % spiked.count])
        }
        let result = try XCTUnwrap(TradableCorridorDetector.detect(
            symbol: "NVDA", bars: bars, nowEpochSeconds: now
        ))
        XCTAssertLessThan(result.price, 101)
    }

    func testEuropeanSessionDoesNotCountPreviousLocalDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Berlin"))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 10, day: 27, hour: 0, minute: 10
        )))
        let now = Int64(date.timeIntervalSince1970)
        let bars = patternBars(endingAt: now, count: 72)

        XCTAssertNil(TradableCorridorDetector.detect(symbol: "SAP.DE", bars: bars, nowEpochSeconds: now))
    }

    private func patternBars(endingAt end: Int64, count: Int) -> [MinuteBar] {
        (0..<count).map { index in
            bar(end - Int64(count - 1 - index) * 60, pattern[index % pattern.count])
        }
    }

    private func bar(_ epoch: Int64, _ close: Double) -> MinuteBar {
        MinuteBar(symbol: "TEST", minuteEpochSeconds: epoch,
                  open: close, high: close + 0.05, low: close - 0.05,
                  close: close, volume: 10_000)
    }
}
