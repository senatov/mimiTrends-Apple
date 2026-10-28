import Observation
import Foundation

@MainActor
@Observable
final class RadarSession {
    private(set) var isScanning = false
    private(set) var isSubscribed = false
    private(set) var lastTrade: TradeTick?
    private(set) var tradeCount = 0
    private(set) var completedBarsStored = 0
    private(set) var signalCount = 0
    private(set) var errorCount = 0
    private(set) var targetSymbols: [String] = []
    private(set) var lastSignal: ScanResult?
    private(set) var errorMessage: String?
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var runID: UUID?

    @discardableResult
    func start(symbols: [String] = [], scan: @escaping @Sendable (UUID) async -> Void) -> UUID {
        stop()
        lastTrade = nil
        tradeCount = 0
        completedBarsStored = 0
        signalCount = 0
        errorCount = 0
        targetSymbols = symbols
        lastSignal = nil
        errorMessage = nil
        let id = UUID()
        runID = id
        isScanning = true
        isSubscribed = false
        scanTask = Task.detached { [weak self] in
            await scan(id)
            await self?.finish(id)
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

    func recordStoredBar(runID id: UUID) {
        guard isScanning, runID == id else { return }
        completedBarsStored += 1
    }

    func recordSignal(_ signal: ScanResult, runID id: UUID) {
        guard isScanning, runID == id else { return }
        lastSignal = signal
        signalCount += 1
    }

    func recordFailure(_ message: String, runID id: UUID) {
        guard isScanning, runID == id else { return }
        errorMessage = message
        errorCount += 1
    }

    private func finish(_ id: UUID) {
        guard runID == id else { return }
        scanTask = nil
        runID = nil
        isScanning = false
        isSubscribed = false
    }
}
