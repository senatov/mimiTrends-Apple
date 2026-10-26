import Foundation
import XCTest
@testable import MiMiTrends

final class FinnhubRadarPipelineTests: XCTestCase {
    func testTradesBecomeStoredBarsAndRapidRiseSignal() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimitrends-pipeline-tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("market.db")
        let pipeline = try FinnhubRadarPipeline(databaseURL: url)
        let observations: [(Int64, Double)] = [
            (12_000, 100), (12_060, 100.1), (12_120, 101.8), (12_180, 100.4)
        ]
        var updates: [FinnhubRadarPipeline.Update] = []
        for (second, price) in observations {
            let trade = TradeTick(
                symbol: "RISE", price: price,
                timestampMillis: second * 1_000 + 1, volume: 1_000
            )
            updates.append(try await pipeline.accept(trade, nowEpochSeconds: second))
        }
        XCTAssertEqual(updates.filter(\.storedBar).count, 3)
        XCTAssertNil(updates[0].signal)
        XCTAssertEqual(updates[3].signal?.windowChangePercent ?? 0, 1.8, accuracy: 1e-9)

        let store = try MarketBarStore(url: url)
        let saved = try await store.loadMinuteBars(symbol: "RISE", fromEpochSeconds: 0)
        XCTAssertEqual(saved.map(\.minuteEpochSeconds), [12_000, 12_060, 12_120])
        XCTAssertEqual(saved.map(\.volumeStatus), [.reported, .reported, .reported])
    }
}
