import Foundation
import XCTest
@testable import MiMiTrends

final class MiminaviInfo1DecoderTests: XCTestCase {
    private let generatedAt = "2026-10-28T12:00:00.000Z"
    private let nowMillis: Int64 = 1_793_188_800_000

    func testDecodesFourPeriodsAndDeduplicatesByInstrumentPath() throws {
        let shared = row("shared", rank: 1)
        let data = try payload(periods: [
            "1d": [shared], "7d": [shared, row("weekly", rank: 2)],
            "30d": [shared], "1y": [shared]
        ])
        let candidates = try MiminaviInfo1Decoder.decode(
            data, sourceID: "miminavi_info1", nowMillis: nowMillis
        )
        XCTAssertEqual(candidates.map(\.instrumentID), [
            "/aktien/shared-aktie", "/aktien/weekly-aktie"
        ])
        XCTAssertEqual(candidates.first?.origin?.page, .allIndices)
        XCTAssertEqual(candidates.first?.origin?.period, .day)
        XCTAssertEqual(candidates.first?.displayName, "shared")
        XCTAssertTrue(candidates.allSatisfy { !$0.isScanReady })
    }

    func testRejectsStaleGenerationAndUntrustedInstrumentURL() throws {
        let periods = [
            "1d": [row("shared", rank: 1)], "7d": [], "30d": [], "1y": []
        ]
        let data = try payload(periods: periods)
        XCTAssertThrowsError(try MiminaviInfo1Decoder.decode(
            data, sourceID: "miminavi_info1", nowMillis: nowMillis + 31 * 60_000
        ))

        var poisoned = periods
        poisoned["1d"]?[0]["url"] = "https://example.com/aktien/shared-aktie"
        XCTAssertThrowsError(try MiminaviInfo1Decoder.decode(
            payload(periods: poisoned), sourceID: "miminavi_info1", nowMillis: nowMillis
        ))
    }

    func testRejectsOversizedRankingAndWrongProvenance() throws {
        var periods = [
            "1d": (1...51).map { row("stock-\($0)", rank: $0) },
            "7d": [], "30d": [], "1y": []
        ]
        XCTAssertThrowsError(try MiminaviInfo1Decoder.decode(
            payload(periods: periods), sourceID: "miminavi_info1", nowMillis: nowMillis
        ))
        periods["1d"] = [row("shared", rank: 1)]
        XCTAssertThrowsError(try MiminaviInfo1Decoder.decode(
            payload(periods: periods, source: "https://example.com"),
            sourceID: "miminavi_info1", nowMillis: nowMillis
        ))
    }

    func testAcceptsNumberedStockDetailPath() throws {
        var numbered = row("l-oreal", rank: 1)
        numbered["url"] = "https://www.wallstreet-online.de/aktien/853888-l-oreal-aktie-1"
        let data = try payload(periods: [
            "1d": [numbered], "7d": [], "30d": [], "1y": []
        ])
        let candidates = try MiminaviInfo1Decoder.decode(
            data, sourceID: "miminavi_info1", nowMillis: nowMillis
        )
        XCTAssertEqual(candidates.first?.instrumentID, "/aktien/853888-l-oreal-aktie-1")
    }

    func testAcceptsStockDetailPathWithoutAktieSuffix() throws {
        var airbus = row("airbus", rank: 1)
        airbus["url"] = "https://www.wallstreet-online.de/aktien/airbus"
        let candidates = try MiminaviInfo1Decoder.decode(
            payload(periods: ["1d": [airbus], "7d": [], "30d": [], "1y": []]),
            sourceID: "miminavi_info1", nowMillis: nowMillis
        )
        XCTAssertEqual(candidates.first?.instrumentID, "/aktien/airbus")
    }

    private func row(_ slug: String, rank: Int) -> [String: Any] {
        [
            "rank": rank, "name": slug, "url": "https://www.wallstreet-online.de/aktien/\(slug)-aktie",
            "isNew": false, "price": 25.5,
            "performance1dPercent": 1.2, "performance7dPercent": 2.3,
            "performance30dPercent": 3.4, "performance1yPercent": 4.5
        ]
    }

    private func payload(periods: [String: [[String: Any]]],
                         source: String = "https://www.wallstreet-online.de/statistik/top-aktien-performance") throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "source": source, "generatedAt": generatedAt, "periods": periods
        ])
    }
}
