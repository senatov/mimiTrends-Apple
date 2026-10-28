import XCTest
@testable import MiMiTrends

final class DiscoveryCandidateSelectorTests: XCTestCase {
    func testInterleavesCategoriesAndDeduplicatesInstrumentPaths() throws {
        let rows = [
            candidate("top-1", .top, rank: 1),
            candidate("top-2", .top, rank: 2),
            candidate("flop-1", .flop, rank: 1),
            candidate("volume-1", .mostTraded, rank: 1),
            candidate("flop-1", .top, rank: 3)
        ]
        let selected = try DiscoveryCandidateSelector.select(rows, sourceID: "fixture")
        XCTAssertEqual(selected.map(\.instrumentID), ["flop-1", "volume-1", "top-1", "top-2"])
    }

    func testBoundsSelectionAtFortyAndRejectsOversizedInput() throws {
        let rows = (1...55).map { candidate("instrument-\($0)", .top, rank: $0) }
        XCTAssertEqual(try DiscoveryCandidateSelector.select(rows, sourceID: "fixture").count, 40)
        XCTAssertThrowsError(try DiscoveryCandidateSelector.select(
            Array(repeating: rows[0], count: 1_001), sourceID: "fixture"
        ))
    }

    func testUnresolvedNameIsNotScanReady() throws {
        let unresolved = candidate("issuer-name", .mostTraded, rank: 1)
        XCTAssertFalse(unresolved.isScanReady)
        XCTAssertNoThrow(try unresolved.validate())
        let resolved = DiscoveryCandidate(
            sourceID: "fixture", instrumentID: "issuer-name", category: .mostTraded,
            rank: 1, observedAtMillis: 1_000,
            resolved: ResolvedMarketSymbol(symbol: "AAPL", exchangeMIC: "XNAS", currency: "USD")
        )
        XCTAssertTrue(resolved.isScanReady)
        XCTAssertNoThrow(try resolved.validate())
        let invalid = DiscoveryCandidate(
            sourceID: "fixture", instrumentID: "issuer-name", category: .mostTraded,
            rank: 1, observedAtMillis: 1_000,
            resolved: ResolvedMarketSymbol(symbol: "AAPL", exchangeMIC: "", currency: "USD")
        )
        XCTAssertThrowsError(try invalid.validate())
    }

    private func candidate(_ id: String, _ category: DiscoveryCategory, rank: Int) -> DiscoveryCandidate {
        DiscoveryCandidate(
            sourceID: "fixture", instrumentID: id, category: category,
            rank: rank, observedAtMillis: 1_000, resolved: nil
        )
    }
}
