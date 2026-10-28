import Foundation

enum AppIdentity {
    static let name = "mimiTrends-iOS"

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    static var windowTitle: String { "\(name) · \(version)" }
}
