import SwiftUI

struct SourceCredentialsView: View {
    @Environment(RadarSession.self) private var radarSession
    @Environment(\.colorScheme) private var colorScheme
    @State private var accounts: [String] = []
    @State private var newSource = ""
    @State private var newSecret = ""
    @State private var message: String?

    private let webhookAccount = "Finnhub webhook secret"

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Market data providers").font(.title2.weight(.semibold))
                    Text("Connected source and locally stored credentials")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                connectionPanel
                CredentialEditor(
                    title: "Finnhub API key",
                    detail: "Used by the active one-symbol trade feed and US bid/ask checks.",
                    accent: .teal,
                    load: { try FinnhubCredentialStore.load() },
                    save: { try FinnhubCredentialStore.save($0) },
                    remove: {
                        try FinnhubCredentialStore.delete()
                        radarSession.stop()
                    }
                )
                CredentialEditor(
                    title: webhookAccount,
                    detail: "Stored for a future webhook integration. The current foreground feed does not use it.",
                    accent: .indigo,
                    load: { try ProviderCredentialStore.load(webhookAccount) },
                    save: { try ProviderCredentialStore.save($0, for: webhookAccount) },
                    remove: { try ProviderCredentialStore.delete(webhookAccount) }
                )
                additionalSourcesPanel
                ForEach(accounts.filter { $0 != webhookAccount }, id: \.self) { account in
                    CredentialEditor(
                        title: account,
                        detail: "Stored locally for a future provider adapter; not used by the current feed.",
                        accent: .blue,
                        load: { try ProviderCredentialStore.load(account) },
                        save: { try ProviderCredentialStore.save($0, for: account) },
                        remove: { try ProviderCredentialStore.delete(account) },
                        onRemove: refreshAccounts
                    )
                }
            }
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .background(TrendsColors.canvas(colorScheme))
        .navigationTitle(AppIdentity.windowTitle)
        .onAppear { refreshAccounts() }
        .onDisappear {
            newSource = ""
            newSecret = ""
        }
    }

    private var connectionPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Finnhub", systemImage: "antenna.radiowaves.left.and.right")
                .font(.headline)
            LabeledContent("Live trades", value: "ws.finnhub.io")
            LabeledContent("US bid/ask", value: "api.finnhub.io")
            Text("These endpoints belong to the current adapter. Tradegate, Euronext, Yahoo Finance, Lang & Schwarz, and external chart URLs from the desktop app are not connected here yet.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel(accent: .teal)
    }

    private var additionalSourcesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Additional source credential").font(.headline)
            Text("Keep an API key or token for a planned source. Saving it does not enable a provider or send it to a server.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            TextField("Source name", text: $newSource)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 500)
            SecretEntryField(title: "API key or token", value: $newSecret)
                .frame(maxWidth: 500)
            TrendsActionButton(title: "Save source credential", systemImage: "key.fill") {
                saveAdditional()
            }
            .disabled(newSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                      newSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if let message {
                Text(message).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel(accent: .cyan)
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
