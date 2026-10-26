import XCTest
@testable import MiMiTrends

@MainActor
final class RadarSessionTests: XCTestCase {
    func testStoppingCancelsAnActiveScan() async {
        let session = RadarSession()
        let started = expectation(description: "Scan started")
        let cancelled = expectation(description: "Scan cancelled")

        XCTAssertFalse(session.isScanning)
        session.start {
            started.fulfill()
            do {
                try await Task.sleep(for: .seconds(60))
            } catch {
                cancelled.fulfill()
            }
        }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertTrue(session.isScanning)

        session.stop()
        await fulfillment(of: [cancelled], timeout: 2)
        XCTAssertFalse(session.isScanning)
    }
}
