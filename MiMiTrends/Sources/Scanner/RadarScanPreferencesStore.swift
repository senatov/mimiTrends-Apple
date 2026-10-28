import Foundation

enum RadarScanPreferencesStore {
    static let key = "radar.scanPreferences.v1"

    static func load(from defaults: UserDefaults = .standard) -> RadarScanPreferences {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(RadarScanPreferences.self, from: data) else {
            return RadarScanPreferences()
        }
        return value.validated
    }

    static func save(_ value: RadarScanPreferences, to defaults: UserDefaults = .standard) throws {
        defaults.set(try JSONEncoder().encode(value.validated), forKey: key)
    }
}
