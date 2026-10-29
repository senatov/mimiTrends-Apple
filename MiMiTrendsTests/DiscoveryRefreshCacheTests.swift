import Foundation
import XCTest
@testable import MiMiTrends

final class DiscoveryRefreshCacheTests: XCTestCase {
    func testRefreshesAfterThirtyMinutes() async throws {
        let clock = DiscoveryTestClock(1_000)
        let source = DiscoveryFixtureSource()
        let cache = DiscoveryRefreshCache(source: source, nowMillis: { clock.now() })

        let first = await cache.refreshIfNeeded()
        XCTAssertEqual(first.snapshot?.candidates.first?.instrumentID, "first")
        XCTAssertTrue(first.lastAttemptSucceeded)
        XCTAssertTrue(first.hasFreshSnapshot(atMillis: clock.now()))
        clock.advance(30 * 60_000 - 1)
        _ = await cache.refreshIfNeeded()
        let beforeBoundary = await source.loadCount
        XCTAssertEqual(beforeBoundary, 1)

        await source.setID("second")
        clock.advance(1)
        let second = await cache.refreshIfNeeded()
        XCTAssertEqual(second.snapshot?.candidates.first?.instrumentID, "second")
        let afterBoundary = await source.loadCount
        XCTAssertEqual(afterBoundary, 2)
    }

    func testFailureRetainsLastSnapshotAndRetriesAfterFiveMinutes() async {
        let clock = DiscoveryTestClock(1_000)
        let source = DiscoveryFixtureSource()
        let cache = DiscoveryRefreshCache(source: source, nowMillis: { clock.now() })
        _ = await cache.refreshIfNeeded()

        await source.setFailure(true)
        clock.advance(30 * 60_000)
        let failed = await cache.refreshIfNeeded()
        XCTAssertEqual(failed.snapshot?.candidates.first?.instrumentID, "first")
        XCTAssertFalse(failed.lastAttemptSucceeded)
        XCTAssertFalse(failed.hasFreshSnapshot(atMillis: clock.now()))
        XCTAssertEqual(failed.nextAttemptAtMillis, clock.now() + 5 * 60_000)
        clock.advance(5 * 60_000 - 1)
        _ = await cache.refreshIfNeeded()
        let callsBeforeRetry = await source.loadCount
        XCTAssertEqual(callsBeforeRetry, 2)

        await source.setFailure(false)
        await source.setID("recovered")
        clock.advance(1)
        let recovered = await cache.refreshIfNeeded()
        XCTAssertEqual(recovered.snapshot?.candidates.first?.instrumentID, "recovered")
        XCTAssertTrue(recovered.lastAttemptSucceeded)
        let callsAfterRetry = await source.loadCount
        XCTAssertEqual(callsAfterRetry, 3)
    }

    func testConcurrentReadersShareOneRefresh() async {
        let source = DiscoveryFixtureSource()
        await source.setDelay(.milliseconds(30))
        let cache = DiscoveryRefreshCache(source: source)
        let results = await withTaskGroup(of: DiscoveryRefreshStatus.self) { group in
            for _ in 0..<10 {
                group.addTask { await cache.refreshIfNeeded() }
            }
            var collected: [DiscoveryRefreshStatus] = []
            for await result in group { collected.append(result) }
            return collected
        }
        XCTAssertEqual(results.count, 10)
        XCTAssertTrue(results.allSatisfy { $0.snapshot?.candidates.count == 1 })
        let requests = await source.loadCount
        XCTAssertEqual(requests, 1)
    }

    func testRestoredSnapshotIsNotReportedAsFreshAfterFailure() async throws {
        let source = DiscoveryFixtureSource()
        await source.setFailure(true)
        let cache = DiscoveryRefreshCache(source: source)
        let saved = DiscoverySnapshot(sourceID: "fixture", refreshedAtMillis: 1_000, candidates: [
            DiscoveryCandidate(
                sourceID: "fixture", instrumentID: "saved", category: .top,
                rank: 1, observedAtMillis: 1_000, resolved: nil
            )
        ])
        try await cache.restore(saved)

        let status = await cache.refreshIfNeeded()
        XCTAssertEqual(status.snapshot, saved)
        XCTAssertFalse(status.lastAttemptSucceeded)
        XCTAssertFalse(status.hasFreshSnapshot(atMillis: 1_000))
    }

    func testFreshnessExpiresAtRefreshBoundary() {
        let snapshot = DiscoverySnapshot(sourceID: "fixture", refreshedAtMillis: 1_000, candidates: [])
        let status = DiscoveryRefreshStatus(
            snapshot: snapshot, lastAttemptSucceeded: true, nextAttemptAtMillis: 1_801_000
        )
        XCTAssertTrue(status.hasFreshSnapshot(atMillis: 1_800_999))
        XCTAssertFalse(status.hasFreshSnapshot(atMillis: 1_801_000))
        XCTAssertFalse(status.hasFreshSnapshot(atMillis: 999))
    }

    func testFreshnessUsesSourceObservationTime() {
        let candidate = DiscoveryCandidate(
            sourceID: "fixture", instrumentID: "first", category: .top,
            rank: 1, observedAtMillis: 1_000, resolved: nil
        )
        let status = DiscoveryRefreshStatus(
            snapshot: DiscoverySnapshot(
                sourceID: "fixture", refreshedAtMillis: 20 * 60_000,
                candidates: [candidate]
            ),
            lastAttemptSucceeded: true, nextAttemptAtMillis: 50 * 60_000
        )
        XCTAssertTrue(status.hasFreshSnapshot(atMillis: 30 * 60_000))
        XCTAssertFalse(status.hasFreshSnapshot(atMillis: 30 * 60_000 + 1_000))
    }

    func testCancellationStopsInFlightRefreshAndAllowsRetry() async throws {
        let source = DiscoveryFixtureSource()
        await source.setDelay(.seconds(1))
        await source.setCancellationAsURLError(true)
        let cache = DiscoveryRefreshCache(source: source)
        let pending = Task { await cache.refreshIfNeeded() }
        for _ in 0..<100 {
            if await source.loadCount > 0 { break }
            try await Task.sleep(for: .milliseconds(2))
        }
        await cache.cancel()
        let cancelled = await pending.value
        XCTAssertNil(cancelled.snapshot)
        XCTAssertEqual(cancelled.nextAttemptAtMillis, 0)

        await source.setDelay(.zero)
        let retried = await cache.refreshIfNeeded()
        XCTAssertTrue(retried.lastAttemptSucceeded)
        XCTAssertEqual(retried.snapshot?.candidates.first?.instrumentID, "first")
    }
}

private final class DiscoveryTestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Int64

    init(_ value: Int64) { self.value = value }

    func now() -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func advance(_ milliseconds: Int64) {
        lock.lock()
        value += milliseconds
        lock.unlock()
    }
}

private actor DiscoveryFixtureSource: DiscoveryCandidateSource {
    nonisolated let sourceID = "fixture"
    private(set) var loadCount = 0
    private var id = "first"
    private var shouldFail = false
    private var cancellationAsURLError = false
    private var delay: Duration?

    func setID(_ value: String) { id = value }
    func setFailure(_ value: Bool) { shouldFail = value }
    func setCancellationAsURLError(_ value: Bool) { cancellationAsURLError = value }
    func setDelay(_ value: Duration) { delay = value }

    func loadCandidates() async throws -> [DiscoveryCandidate] {
        loadCount += 1
        if let delay {
            do { try await Task.sleep(for: delay) }
            catch {
                if cancellationAsURLError { throw URLError(.cancelled) }
                throw error
            }
        }
        if shouldFail { throw DiscoveryDataError.invalidCandidate }
        return [DiscoveryCandidate(
            sourceID: sourceID, instrumentID: id, category: .top,
            rank: 1, observedAtMillis: 1_000, resolved: nil
        )]
    }
}
