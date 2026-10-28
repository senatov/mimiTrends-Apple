import XCTest
@testable import MiMiTrends

final class ProviderCredentialStoreTests: XCTestCase {
    func testAccountsCanBeSavedRevealedAndRemoved() throws {
        let service = "org.senatov.mimitrends.apple.provider-tests.\(UUID().uuidString)"
        defer { try? ProviderCredentialStore.delete("My feed", service: service) }

        XCTAssertEqual(try ProviderCredentialStore.accounts(service: service), [])
        try ProviderCredentialStore.save(" first-token ", for: "My feed", service: service)
        XCTAssertEqual(try ProviderCredentialStore.load("My feed", service: service), "first-token")
        XCTAssertEqual(try ProviderCredentialStore.accounts(service: service), ["My feed"])

        try ProviderCredentialStore.save("replacement", for: "My feed", service: service)
        XCTAssertEqual(try ProviderCredentialStore.load("My feed", service: service), "replacement")
        try ProviderCredentialStore.delete("My feed", service: service)
        XCTAssertNil(try ProviderCredentialStore.load("My feed", service: service))
    }

    func testEmptyCredentialIsRejected() {
        XCTAssertThrowsError(try ProviderCredentialStore.save(" ", for: "My feed"))
    }
}
