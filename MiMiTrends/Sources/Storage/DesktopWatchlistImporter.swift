import Foundation

struct DesktopWatchlistImportSummary: Sendable {
    let entryCount: Int
    let insertedCount: Int
}

enum DesktopWatchlistImporter {
    static func importSnapshot(
        at url: URL, into store: WatchlistStore
    ) async throws -> DesktopWatchlistImportSummary {
        let entries = try await Task.detached(priority: .userInitiated) {
            let hasScopedAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasScopedAccess { url.stopAccessingSecurityScopedResource() }
            }
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size > 0, size <= 128_000 else {
                throw DesktopWatchlistImportError.invalidSnapshot
            }
            let data = try Data(contentsOf: url)
            guard data.count <= 128_000,
                  let snapshot = try? JSONDecoder().decode(
                      DesktopWatchlistSnapshot.self, from: data
                  ) else {
                throw DesktopWatchlistImportError.invalidSnapshot
            }
            guard snapshot.format == "mimitrends-watchlist",
                  snapshot.version == 1,
                  !snapshot.entries.isEmpty,
                  snapshot.entries.count <= 500,
                  snapshot.entries.allSatisfy({
                      $0.addedAtMillis > 0 &&
                      (try? WatchlistStore.normalize($0.symbol)) == $0.symbol
                  }),
                  Set(snapshot.entries.map(\.symbol)).count == snapshot.entries.count,
                  snapshot.entries == snapshot.entries.sorted(by: {
                      ($0.addedAtMillis, $0.symbol) < ($1.addedAtMillis, $1.symbol)
                  }) else {
                throw DesktopWatchlistImportError.invalidSnapshot
            }
            return snapshot.entries
        }.value
        let inserted = try await store.importEntries(entries)
        return DesktopWatchlistImportSummary(
            entryCount: entries.count, insertedCount: inserted
        )
    }
}

private struct DesktopWatchlistSnapshot: Decodable {
    let format: String
    let version: Int
    let entries: [WatchlistEntry]
}

enum DesktopWatchlistImportError: LocalizedError {
    case invalidSnapshot

    var errorDescription: String? {
        "The selected file is not a valid MiMiTrends watchlist snapshot."
    }
}
