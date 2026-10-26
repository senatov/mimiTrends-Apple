import Observation
import Foundation

@MainActor
@Observable
final class RadarSession {
    private(set) var isScanning = false
    private(set) var isSubscribed = false
    private(set) var lastTrade: TradeTick?
    private(set) var tradeCount = 0
    private(set) var errorMessage: String?
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var runID: UUID?

    @discardableResult
    func start(scan: @escaping @Sendable (UUID) async -> Void) -> UUID {
        stop()
        lastTrade = nil
        tradeCount = 0
        errorMessage = nil
        let id = UUID()
        runID = id
        isScanning = true
        isSubscribed = false
        scanTask = Task { [weak self] in
            await scan(id)
            self?.finish(id)
        }
        return id
    }

    func stop() {
        scanTask?.cancel()
        scanTask = nil
        runID = nil
        isScanning = false
        isSubscribed = false
    }

    func markSubscribed(runID id: UUID) {
        guard isScanning, runID == id else { return }
        isSubscribed = true
    }

    func record(_ trade: TradeTick, runID id: UUID) {
        guard isScanning, runID == id else { return }
        lastTrade = trade
        tradeCount += 1
    }

    func recordFailure(_ message: String, runID id: UUID) {
        guard isScanning, runID == id else { return }
        errorMessage = message
    }

    private func finish(_ id: UUID) {
        guard runID == id else { return }
        scanTask = nil
        runID = nil
        isScanning = false
        isSubscribed = false
    }
}
