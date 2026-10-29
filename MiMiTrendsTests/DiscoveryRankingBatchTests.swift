import XCTest
@testable import MiMiTrends

final class DiscoveryRankingBatchTests: XCTestCase {
    func testCatalogMatchesRequestedPages() {
        XCTAssertEqual(DiscoveryRankingPage.allCases.map(\.path), [
            "/statistik/top-aktien-performance",
            "/statistik/top-dax-aktien-performance",
            "/statistik/top-cdax-aktien-performance",
            "/statistik/top-mdax-aktien-performance",
            "/statistik/top-tecdax-aktien-performance",
            "/statistik/top-sdax-aktien-performance",
            "/statistik/top-eurostoxx-aktien-performance",
            "/statistik/top-dowjones-aktien-performance",
            "/statistik/top-nasdaq100-aktien-performance",
            "/statistik/top-sp500-aktien-performance",
            "/statistik/trending-stocks"
        ])
    }

    func testFullTablesPreserveOriginAndPreferDailyRankOnDuplicate() throws {
        let daily = batch(.dax, .day, ids: (1...40).map { "dax-\($0)" })
        let weekly = batch(.dax, .week, ids: ["dax-1", "weekly-only"])
        let cdax = batch(.cdax, .day, ids: (1...50).map { "cdax-\($0)" })
        let result = try DiscoveryRankingAssembler.assemble([weekly, cdax, daily], sourceID: "fixture")

        XCTAssertEqual(result.candidates.count, 91)
        XCTAssertEqual(result.candidates.first?.origin?.period, .day)
        XCTAssertEqual(result.candidates.first?.origin?.page, .dax)
        XCTAssertTrue(result.emptyRankings.isEmpty)
        XCTAssertEqual(result.availableRankings.count, 3)
    }

    func testEmptyMorningRankingIsReportedWithoutInventingRows() throws {
        let empty = batch(.dax, .day, ids: [])
        let trending = batch(.trending, .activity, ids: ["active-1"])
        let result = try DiscoveryRankingAssembler.assemble([empty, trending], sourceID: "fixture")

        XCTAssertEqual(result.candidates.map(\.instrumentID), ["active-1"])
        XCTAssertEqual(result.candidates.first?.category, .trending)
        XCTAssertTrue(result.emptyRankings.contains(DiscoveryRankingKey(page: .dax, period: .day)))
    }

    func testCatalogPagesCanEachContributeFiftyRows() throws {
        let batches = DiscoveryRankingPage.allCases.map { page in
            batch(page, page.isIndexRanking ? .day : .activity,
                  ids: (1...50).map { "\(page.rawValue)-\($0)" })
        }
        let result = try DiscoveryRankingAssembler.assemble(batches, sourceID: "fixture")
        XCTAssertEqual(result.availableRankings.count, 11)
        XCTAssertEqual(result.candidates.count, 550)
    }

    func testRejectsOversizedDuplicateAndMismatchedRankings() {
        let oversized = batch(.cdax, .day, ids: (1...51).map { "stock-\($0)" })
        XCTAssertThrowsError(try oversized.candidates(sourceID: "fixture"))

        let daily = batch(.dax, .day, ids: ["stock-1"])
        XCTAssertThrowsError(try DiscoveryRankingAssembler.assemble([daily, daily], sourceID: "fixture"))

        let invalidPeriod = batch(.dax, .activity, ids: ["stock-1"])
        XCTAssertThrowsError(try invalidPeriod.candidates(sourceID: "fixture"))
    }

    private func batch(_ page: DiscoveryRankingPage, _ period: DiscoveryRankingPeriod,
                       ids: [String]) -> DiscoveryRankingBatch {
        DiscoveryRankingBatch(
            origin: DiscoveryRankingOrigin(page: page, period: period),
            observedAtMillis: 1_000,
            rows: ids.enumerated().map { offset, id in
                DiscoveryRankingRow(instrumentID: id, rank: offset + 1, resolved: nil)
            }
        )
    }
}
