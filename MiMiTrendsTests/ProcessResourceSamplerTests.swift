#if os(macOS)
import XCTest
@testable import MiMiTrends

final class ProcessResourceSamplerTests: XCTestCase {
    func testOwnProcessMetricsAreAvailable() {
        let sample = ProcessResourceSampler.capture()
        XCTAssertGreaterThan(sample.footprintBytes, 0)
        XCTAssertGreaterThan(sample.threadCount, 0)
        XCTAssertLessThanOrEqual(sample.compressedBytes, sample.footprintBytes)
    }
}
#endif
