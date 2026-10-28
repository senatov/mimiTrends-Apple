import XCTest
@testable import MiMiTrends

final class FinnhubCredentialStoreTests: XCTestCase {
    func testSaveReplaceAndDeleteAcrossLocalStore() throws {
        let service = "org.senatov.mimitrends.apple.tests.\(UUID().uuidString)"
        defer { try? FinnhubCredentialStore.delete(service: service) }

        XCTAssertNil(try FinnhubCredentialStore.load(service: service))
        try FinnhubCredentialStore.save(" first-key ", service: service)
        XCTAssertEqual(try FinnhubCredentialStore.load(service: service), "first-key")
        try FinnhubCredentialStore.save("replacement", service: service)
        XCTAssertEqual(try FinnhubCredentialStore.load(service: service), "replacement")
        try FinnhubCredentialStore.delete(service: service)
        XCTAssertNil(try FinnhubCredentialStore.load(service: service))
    }
}
