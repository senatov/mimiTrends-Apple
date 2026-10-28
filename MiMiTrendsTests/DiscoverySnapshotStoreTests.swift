import Foundation
import XCTest
@testable import MiMiTrends

final class DiscoverySnapshotStoreTests: XCTestCase {
    func testSourceSpecificPathRejectsTraversal() throws {
        let first = try DiscoverySnapshotStore.defaultURL(for: "licensed-feed")
        let second = try DiscoverySnapshotStore.defaultURL(for: "other-feed")
        XCTAssertNotEqual(first, second)
        XCTAssertThrowsError(try DiscoverySnapshotStore.defaultURL(for: "../outside"))
    }

    func testSnapshotSurvivesReopenAndRejectsCorruption() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("discovery.json")
        let snapshot = DiscoverySnapshot(sourceID: "fixture", refreshedAtMillis: 1_000, candidates: [
            DiscoveryCandidate(
                sourceID: "fixture", instrumentID: "issuer-1", category: .flop,
                rank: 1, observedAtMillis: 1_000, resolved: nil
            )
        ])
        let store = DiscoverySnapshotStore(url: url)
        try await store.save(snapshot)
        let reopened = DiscoverySnapshotStore(url: url)
        let loaded = try await reopened.load()
        XCTAssertEqual(loaded, snapshot)

        try Data("not JSON".utf8).write(to: url)
        do {
            _ = try await reopened.load()
            XCTFail("Corrupt snapshots must be rejected")
        } catch DiscoveryDataError.invalidSnapshot {
            // The caller can keep its previous in-memory snapshot.
        }
    }

    func testLegacyCandidateWithoutRankingOriginStillDecodes() throws {
        let json = """
        {"sourceID":"fixture","instrumentID":"saved","category":"top",\
        "rank":1,"observedAtMillis":1000,"resolved":null}
        """
        let candidate = try JSONDecoder().decode(DiscoveryCandidate.self, from: Data(json.utf8))
        XCTAssertNil(candidate.origin)
        XCTAssertNoThrow(try candidate.validate())
    }
}
