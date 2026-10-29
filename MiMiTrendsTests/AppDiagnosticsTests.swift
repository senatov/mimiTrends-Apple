import Foundation
import XCTest
@testable import MiMiTrends

final class AppDiagnosticsTests: XCTestCase {
    func testWritesTimestampedDiagnosticEventsToRequestedFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("diagnostics-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("events.log")
        let diagnostics = AppDiagnostics(preferredURL: url)
        diagnostics.record(.warning, "Charts", "load-complete", "symbol=ORCL bars=0")

        XCTAssertEqual(diagnostics.fileURL(), url)
        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("WARN [Charts] load-complete symbol=ORCL bars=0"))
    }
}
