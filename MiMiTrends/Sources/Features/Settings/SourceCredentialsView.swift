import SwiftUI

struct SourceCredentialsView: View {
    @Environment(RadarSession.self) private var radarSession
    @State private var accounts: [String] = []
    @State private var newSource = ""
    @State private var newSecret = ""
    @State private var message: String?

    private let webhookAccount = "Finnhub webhook secret"

    var body: some View {
        SettingsPage(title: "Market data providers", subtitle: "Connected source and locally stored credentials") { width in
            if width >= 900 {
                HStack(alignment: .top, spacing: 18) {
                    connectionPanel
                    additionalSourcesPanel
                }
            } else {
                connectionPanel
                additionalSourcesPanel
            }
            if width >= 900 {
                HStack(alignment: .top, spacing: 18) {
                    finnhubKeyEditor
                    webhookEditor
                }
            } else {
                finnhubKeyEditor
                webhookEditor
            }
            ForEach(accounts.filter { $0 != webhookAccount }, id: \.self) { account in
                CredentialEditor(
                    title: account,
                    detail: "Stored locally for a future provider adapter; not used by the current feed.",
                    load: { try ProviderCredentialStore.load(account) },
                    save: { try ProviderCredentialStore.save($0, for: account) },
                    remove: { try ProviderCredentialStore.delete(account) },
                    onRemove: refreshAccounts
                )
            }
        }
        .onAppear { refreshAccounts() }
        .onDisappear {
            newSource = ""
            newSecret = ""
        }
    }

    private var finnhubKeyEditor: some View {
        CredentialEditor(
            title: "Finnhub API key",
            detail: "Used by the active one-symbol trade feed and US bid/ask checks.",
            load: { try FinnhubCredentialStore.load() },
            save: { try FinnhubCredentialStore.save($0) },
            remove: {
                try FinnhubCredentialStore.delete()
                radarSession.stop()
            }
        )
    }

    private var webhookEditor: some View {
        CredentialEditor(
            title: webhookAccount,
            detail: "Stored for a future webhook integration. The current foreground feed does not use it.",
            load: { try ProviderCredentialStore.load(webhookAccount) },
            save: { try ProviderCredentialStore.save($0, for: webhookAccount) },
            remove: { try ProviderCredentialStore.delete(webhookAccount) }
        )
    }

    private var connectionPanel: some View {
        SettingsGroup(title: "Finnhub") {
            LabeledContent("Live trades", value: "ws.finnhub.io")
            LabeledContent("US bid/ask", value: "api.finnhub.io")
            Text("These endpoints belong to the current adapter. Tradegate, Euronext, Yahoo Finance, Lang & Schwarz, and external chart URLs from the desktop app are not connected here yet.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var additionalSourcesPanel: some View {
        SettingsGroup(title: "Additional source credential") {
            Text("Keep an API key or token for a planned source. Saving it does not enable a provider or send it to a server.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            TextField("Source name", text: $newSource)
                .textFieldStyle(.roundedBorder)
            SecretEntryField(title: "API key or token", value: $newSecret)
            TrendsActionButton(title: "Save source credential", systemImage: "key.fill") {
                saveAdditional()
            }
            .disabled(newSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                      newSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if let message {
                Text(message).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private func saveAdditional() {
        let name = newSource.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.localizedCaseInsensitiveCompare(webhookAccount) != .orderedSame,
              name.localizedCaseInsensitiveCompare("Finnhub API key") != .orderedSame else {
            message = "Use the Finnhub field above for this credential."
            return
        }
        guard !accounts.contains(where: { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            message = "This source already exists. Edit its credential below."
            return
        }
        do {
            try ProviderCredentialStore.save(newSecret, for: name)
            newSource = ""
            newSecret = ""
            refreshAccounts()
            message = "Credential saved in Keychain."
        } catch {
            message = error.localizedDescription
        }
    }

    private func refreshAccounts() {
        do {
            accounts = try ProviderCredentialStore.accounts()
        } catch {
            message = error.localizedDescription
        }
    }
}
