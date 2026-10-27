import Foundation
import SQLite3

struct DesktopBarImportSummary: Sendable {
    let symbol: String
    let barCount: Int
    let changedCount: Int
}

enum DesktopBarSnapshotImporter {
    static func importSnapshot(at url: URL, into databaseURL: URL) async throws -> DesktopBarImportSummary {
        try await Task.detached(priority: .userInitiated) {
            let hasScopedAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasScopedAccess { url.stopAccessingSecurityScopedResource() }
            }
            let snapshot = try DesktopBarSnapshotReader(url: url).read()
            let store = try MarketBarStore(url: databaseURL)
            let changed = try await store.upsertBatch(snapshot.bars)
            return DesktopBarImportSummary(
                symbol: snapshot.symbol, barCount: snapshot.bars.count, changedCount: changed
            )
        }.value
    }
}

private struct DesktopBarSnapshot: Sendable {
    let symbol: String
    let bars: [MinuteBar]
}

private final class DesktopBarSnapshotReader {
    private let database: OpaquePointer

    init(url: URL) throws {
        var connection: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &connection, flags, nil) == SQLITE_OK,
              let connection else {
            if let connection { sqlite3_close(connection) }
            throw DesktopBarSnapshotError.invalidSnapshot
        }
        database = connection
    }

    deinit { sqlite3_close(database) }

    func read() throws -> DesktopBarSnapshot {
        guard try scalar("PRAGMA journal_mode") == "delete",
              try scalar("PRAGMA quick_check") == "ok" else {
            throw DesktopBarSnapshotError.invalidSnapshot
        }
        let metadata = try prepare("SELECT format_version, symbol FROM export_metadata")
        defer { sqlite3_finalize(metadata) }
        guard sqlite3_step(metadata) == SQLITE_ROW,
              sqlite3_column_int(metadata, 0) == 1,
              let symbol = Self.text(metadata, column: 1),
              !symbol.isEmpty, symbol == symbol.uppercased(),
              !symbol.contains(where: \.isWhitespace),
              sqlite3_step(metadata) == SQLITE_DONE else {
            throw DesktopBarSnapshotError.invalidSnapshot
        }

        let statement = try prepare("""
            SELECT symbol, minute_epoch, open, high, low, close, volume,
                   volume_status, source_currency, currency_status
            FROM minute_bars ORDER BY minute_epoch LIMIT 361
            """)
        defer { sqlite3_finalize(statement) }
        var bars: [MinuteBar] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { break }
            guard result == SQLITE_ROW, bars.count < 360,
                  let rowSymbol = Self.text(statement, column: 0), rowSymbol == symbol,
                  sqlite3_column_type(statement, 1) == SQLITE_INTEGER,
                  (2...6).allSatisfy({ Self.isNumeric(statement, column: Int32($0)) }),
                  let statusName = Self.text(statement, column: 7),
                  let status = VolumeStatus(rawValue: statusName),
                  let currency = Self.text(statement, column: 8),
                  currency == Self.currency(for: symbol),
                  Self.text(statement, column: 9) == "INFERRED" else {
                throw DesktopBarSnapshotError.invalidSnapshot
            }
            let bar = MinuteBar(
                symbol: symbol,
                minuteEpochSeconds: sqlite3_column_int64(statement, 1),
                open: sqlite3_column_double(statement, 2),
                high: sqlite3_column_double(statement, 3),
                low: sqlite3_column_double(statement, 4),
                close: sqlite3_column_double(statement, 5),
                volume: sqlite3_column_double(statement, 6),
                volumeStatus: status
            )
            guard bar.isValid,
                  bars.last.map({ $0.minuteEpochSeconds < bar.minuteEpochSeconds }) ?? true else {
                throw DesktopBarSnapshotError.invalidSnapshot
            }
            bars.append(bar)
        }
        guard !bars.isEmpty else { throw DesktopBarSnapshotError.invalidSnapshot }
        return DesktopBarSnapshot(symbol: symbol, bars: bars)
    }

    private func scalar(_ sql: String) throws -> String? {
        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw DesktopBarSnapshotError.invalidSnapshot
        }
        return Self.text(statement, column: 0)
    }

    private func prepare(_ sql: String) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else { throw DesktopBarSnapshotError.invalidSnapshot }
        return statement
    }

    private static func text(_ statement: OpaquePointer, column: Int32) -> String? {
        guard let value = sqlite3_column_text(statement, column) else { return nil }
        return String(cString: value)
    }

    private static func isNumeric(_ statement: OpaquePointer, column: Int32) -> Bool {
        let type = sqlite3_column_type(statement, column)
        return type == SQLITE_INTEGER || type == SQLITE_FLOAT
    }

    private static func currency(for symbol: String) -> String {
        [".DE", ".F", ".PA", ".AS", ".MI", ".HE"].contains(where: symbol.hasSuffix) ? "EUR" : "USD"
    }
}

enum DesktopBarSnapshotError: LocalizedError {
    case invalidSnapshot

    var errorDescription: String? {
        "The selected file is not a valid MiMiTrends minute-bar snapshot."
    }
}
