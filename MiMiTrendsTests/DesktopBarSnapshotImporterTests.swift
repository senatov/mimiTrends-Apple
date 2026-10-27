import Foundation
import SQLite3
import XCTest
@testable import MiMiTrends

final class DesktopBarSnapshotImporterTests: XCTestCase {
    func testValidSnapshotImportsOnce() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshotURL = directory.appendingPathComponent("bars.sqlite")
        let nativeURL = directory.appendingPathComponent("native.sqlite")
        try makeSnapshot(at: snapshotURL)

        let first = try await DesktopBarSnapshotImporter.importSnapshot(at: snapshotURL, into: nativeURL)
        let second = try await DesktopBarSnapshotImporter.importSnapshot(at: snapshotURL, into: nativeURL)
        let store = try MarketBarStore(url: nativeURL)
        let loaded = try await store.loadMinuteBars(symbol: "AAPL", fromEpochSeconds: 0)
        XCTAssertEqual(first.symbol, "AAPL")
        XCTAssertEqual(first.barCount, 2)
        XCTAssertEqual(first.changedCount, 2)
        XCTAssertEqual(second.changedCount, 0)
        XCTAssertEqual(loaded.map(\.minuteEpochSeconds), [60, 120])
    }

    func testInvalidSnapshotDoesNotCreateNativeDatabase() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshotURL = directory.appendingPathComponent("bars.sqlite")
        let nativeURL = directory.appendingPathComponent("native.sqlite")
        try makeSnapshot(at: snapshotURL, currency: "EUR")
        do {
            _ = try await DesktopBarSnapshotImporter.importSnapshot(at: snapshotURL, into: nativeURL)
            XCTFail("Mismatched source currency was accepted")
        } catch DesktopBarSnapshotError.invalidSnapshot {
            XCTAssertFalse(FileManager.default.fileExists(atPath: nativeURL.path))
        }
    }

    func testWalDatabaseIsNotAcceptedAsPortableSnapshot() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshotURL = directory.appendingPathComponent("bars.sqlite")
        try makeSnapshot(at: snapshotURL)
        var connection: OpaquePointer?
        XCTAssertEqual(sqlite3_open(snapshotURL.path, &connection), SQLITE_OK)
        if let connection {
            try execute("PRAGMA journal_mode=WAL", on: connection)
            sqlite3_close(connection)
        }
        do {
            _ = try await DesktopBarSnapshotImporter.importSnapshot(
                at: snapshotURL, into: directory.appendingPathComponent("native.sqlite")
            )
            XCTFail("WAL database was accepted")
        } catch DesktopBarSnapshotError.invalidSnapshot {
            // A live desktop database may have uncheckpointed data in its WAL sidecar.
        }
    }

    private func makeSnapshot(at url: URL, currency: String = "USD") throws {
        var connection: OpaquePointer?
        guard sqlite3_open(url.path, &connection) == SQLITE_OK, let connection else {
            throw DesktopBarSnapshotError.invalidSnapshot
        }
        defer { sqlite3_close(connection) }
        try execute("CREATE TABLE export_metadata(format_version INTEGER, symbol TEXT, exported_at INTEGER)", on: connection)
        try execute("INSERT INTO export_metadata VALUES(1, 'AAPL', 1000)", on: connection)
        try execute("""
            CREATE TABLE minute_bars(
                symbol TEXT, minute_epoch INTEGER, open REAL, high REAL, low REAL,
                close REAL, volume REAL, volume_status TEXT, source_currency TEXT,
                currency_status TEXT)
            """, on: connection)
        for minute in [60, 120] {
            try execute("""
                INSERT INTO minute_bars VALUES(
                    'AAPL', \(minute), 100, 101, 99, 100.5, 1000, 'REPORTED', '\(currency)', 'INFERRED')
                """, on: connection)
        }
    }

    private func execute(_ sql: String, on connection: OpaquePointer) throws {
        guard sqlite3_exec(connection, sql, nil, nil, nil) == SQLITE_OK else {
            throw DesktopBarSnapshotError.invalidSnapshot
        }
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimitrends-import-tests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
