import SwiftUI

struct SettingsView: View {
    @Environment(RadarSession.self) private var radarSession
    @State private var apiKeyDraft = ""
    @State private var hasStoredKey = false
    @State private var credentialMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Finnhub") {
                    SecureField("API key", text: $apiKeyDraft)
                    HStack {
                        TrendsActionButton(title: "Save key", systemImage: "key.fill") { saveKey() }
                            .disabled(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if hasStoredKey {
                            TrendsActionButton(
                                title: "Remove key", systemImage: "trash",
                                tint: .red, role: .destructive
                            ) { removeKey() }
                        }
                    }
                    Text(hasStoredKey ? "API key stored in Keychain on this device." : "No API key stored.")
                        .foregroundStyle(.secondary)
                    if let credentialMessage {
                        Text(credentialMessage).foregroundStyle(.red)
                    }
                }

                Section("Scanning") {
                    Text("Scanning stops whenever the app is no longer active.")
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    LabeledContent(
                        "Version",
                        value: AppIdentity.version
                    )
                    LabeledContent("Platforms", value: "iOS 27 · macOS 27")
                }
            }
            .navigationTitle(AppIdentity.windowTitle)
            .onAppear { refreshKeyStatus() }
            .onDisappear { apiKeyDraft = "" }
        }
    }

    private func refreshKeyStatus() {
        do {
            hasStoredKey = try FinnhubCredentialStore.load() != nil
            credentialMessage = nil
        } catch {
            credentialMessage = error.localizedDescription
        }
    }

    private func saveKey() {
        do {
            try FinnhubCredentialStore.save(apiKeyDraft)
            apiKeyDraft = ""
            refreshKeyStatus()
        } catch {
            credentialMessage = error.localizedDescription
        }
    }

    private func removeKey() {
        do {
            try FinnhubCredentialStore.delete()
            radarSession.stop()
            apiKeyDraft = ""
            refreshKeyStatus()
        } catch {
            credentialMessage = error.localizedDescription
        }
    }
}
