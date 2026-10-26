import Observation
import Foundation

@MainActor
@Observable
final class RadarSession {
    private(set) var isScanning = false
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var runID: UUID?

    func start(scan: @escaping @Sendable () async -> Void) {
        stop()
        let id = UUID()
        runID = id
        isScanning = true
        scanTask = Task { [weak self] in
            await scan()
            self?.finish(id)
        }
    }

    func stop() {
        scanTask?.cancel()
        scanTask = nil
        runID = nil
        isScanning = false
    }

    private func finish(_ id: UUID) {
        guard runID == id else { return }
        scanTask = nil
        runID = nil
        isScanning = false
    }
}
