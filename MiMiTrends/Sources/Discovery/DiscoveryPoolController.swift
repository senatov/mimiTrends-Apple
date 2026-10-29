import Foundation

actor DiscoveryPoolController {
    private let cache: DiscoveryRefreshCache
    private var restored = false
    private var lastSavedAtMillis: Int64?

    init() {
        cache = DiscoveryRefreshCache(source: MiminaviInfo1Source())
    }

    func refresh() async -> DiscoveryRefreshStatus {
        if !restored {
            restored = true
            if let store = try? snapshotStore(),
               let saved = try? await store.load() {
                try? await cache.restore(saved)
                lastSavedAtMillis = saved.refreshedAtMillis
            }
        }
        let status = await cache.refreshIfNeeded()
        if status.lastAttemptSucceeded, let snapshot = status.snapshot,
           lastSavedAtMillis != snapshot.refreshedAtMillis,
           let store = try? snapshotStore() {
            if (try? await store.save(snapshot)) != nil {
                lastSavedAtMillis = snapshot.refreshedAtMillis
            }
        }
        return status
    }

    func stop() async {
        await cache.cancel()
    }

    private func snapshotStore() throws -> DiscoverySnapshotStore {
        DiscoverySnapshotStore(url: try DiscoverySnapshotStore.defaultURL(for: "miminavi_info1"))
    }
}
