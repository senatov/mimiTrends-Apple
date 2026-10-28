import Foundation
import XCTest
@testable import MiMiTrends

final class DesktopWatchlistImporterTests: XCTestCase {
    func testValidSnapshotMergesWithoutReplacingExistingEntries() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshotURL = directory.appendingPathComponent("watchlist.json")
        let store = try WatchlistStore(url: directory.appendingPathComponent("native.db"))
        try await store.add("AAPL", atMillis: 50)
        try writeSnapshot(at: snapshotURL, entries: [
            ["symbol": "AAPL", "added_at": 100],
            ["symbol": "IFX.DE", "added_at": 200],
        ])

        let first = try await DesktopWatchlistImporter.importSnapshot(at: snapshotURL, into: store)
        let second = try await DesktopWatchlistImporter.importSnapshot(at: snapshotURL, into: store)
        let entries = try await store.load()

        XCTAssertEqual(first.entryCount, 2)
        XCTAssertEqual(first.insertedCount, 1)
        XCTAssertEqual(second.insertedCount, 0)
        XCTAssertEqual(entries.map(\.symbol), ["AAPL", "IFX.DE"])
        XCTAssertEqual(entries.first?.addedAtMillis, 50)
    }

    func testInvalidSnapshotLeavesStoreUntouched() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshotURL = directory.appendingPathComponent("watchlist.json")
        let store = try WatchlistStore(url: directory.appendingPathComponent("native.db"))
        try writeSnapshot(at: snapshotURL, entries: [
            ["symbol": "AAPL", "added_at": 100],
            ["symbol": "bad symbol", "added_at": 200],
        ])

        do {
            _ = try await DesktopWatchlistImporter.importSnapshot(at: snapshotURL, into: store)
            XCTFail("Invalid symbol was accepted")
        } catch DesktopWatchlistImportError.invalidSnapshot {
            let entries = try await store.load()
            XCTAssertTrue(entries.isEmpty)
        }
    }

    func testOversizedSnapshotIsRejected() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshotURL = directory.appendingPathComponent("watchlist.json")
        let store = try WatchlistStore(url: directory.appendingPathComponent("native.db"))
        try Data(repeating: 32, count: 128_001).write(to: snapshotURL)

        do {
            _ = try await DesktopWatchlistImporter.importSnapshot(at: snapshotURL, into: store)
            XCTFail("Oversized file was accepted")
        } catch DesktopWatchlistImportError.invalidSnapshot {
            let entries = try await store.load()
            XCTAssertTrue(entries.isEmpty)
        }
    }

    func testMalformedSnapshotHasConciseError() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshotURL = directory.appendingPathComponent("watchlist.json")
        let store = try WatchlistStore(url: directory.appendingPathComponent("native.db"))
        try Data("not json".utf8).write(to: snapshotURL)

        do {
            _ = try await DesktopWatchlistImporter.importSnapshot(at: snapshotURL, into: store)
            XCTFail("Malformed JSON was accepted")
        } catch DesktopWatchlistImportError.invalidSnapshot {
            let entries = try await store.load()
            XCTAssertTrue(entries.isEmpty)
        }
    }

    private func writeSnapshot(at url: URL, entries: [[String: Any]]) throws {
        let payload: [String: Any] = [
            "format": "mimitrends-watchlist", "version": 1, "entries": entries,
        ]
        try JSONSerialization.data(withJSONObject: payload).write(to: url)
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimitrends-watchlist-import-tests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
