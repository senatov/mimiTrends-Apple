import Foundation
import XCTest
@testable import MiMiTrends

final class RadarScanPreferencesTests: XCTestCase {
    func testDesktopThresholdDefaultsAreAvailableWithoutSavedPreferences() {
        let defaults = UserDefaults(suiteName: "RadarScanPreferencesTests.\(UUID().uuidString)")!
        let settings = RadarScanPreferencesStore.load(from: defaults)

        XCTAssertEqual(settings.crashPercent, 0.35)
        XCTAssertEqual(settings.risePercent, 0.8)
        XCTAssertEqual(settings.sustainedMoveMinimumTurnover, 50_000_000)
    }

    func testSettingsRoundTripAndBounds() throws {
        let suite = "RadarScanPreferencesTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var settings = RadarScanPreferences()
        settings.risePercent = 1.35
        settings.crashWindowMinutes = 999
        settings.minimumTurnover = .infinity

        try RadarScanPreferencesStore.save(settings, to: defaults)
        let restored = RadarScanPreferencesStore.load(from: defaults)

        XCTAssertEqual(restored.risePercent, 1.35)
        XCTAssertEqual(restored.crashWindowMinutes, 15)
        XCTAssertEqual(restored.minimumTurnover, 250_000)
    }
}
