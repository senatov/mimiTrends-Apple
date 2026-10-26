import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    LabeledContent("Version", value: "0.1.0")
                    LabeledContent("Platforms", value: "iOS 27 · macOS 27")
                }

                Section("Scanning") {
                    Text("Scanning stops whenever the app is no longer active.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
