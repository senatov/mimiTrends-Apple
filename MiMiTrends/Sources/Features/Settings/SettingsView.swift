import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appearance.theme.v1") private var theme = "light"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Settings").font(.title2.weight(.semibold))
                        Text("Sources, signal rules, and display preferences")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    sourcesPanel
                    detectionPanel
                    appearancePanel
                    aboutPanel
                }
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
                .padding(14)
            }
            .background(TrendsColors.canvas(colorScheme))
            .navigationTitle(AppIdentity.windowTitle)
        }
    }

    private var sourcesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Data sources", systemImage: "antenna.radiowaves.left.and.right")
                .font(.headline)
            NavigationLink {
                SourceCredentialsView()
            } label: {
                Label("Manage keys and tokens", systemImage: "key.horizontal")
            }
            .buttonStyle(TrendsActionButtonStyle())
            Text("Finnhub is the active feed. Open the credential editor to manage its API key.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel(accent: .teal)
    }

    private var detectionPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Signal detection").font(.headline)
            NavigationLink {
                RadarScanSettingsView()
            } label: {
                Label("Rapid-move thresholds", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(TrendsActionButtonStyle())
            Text("The current feed scans one symbol through Finnhub and stops outside the foreground. Desktop provider switches, market universes, anomaly settings, and polling intervals are not active here yet.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel(accent: .blue)
    }

    private var appearancePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appearance").font(.headline)
            Picker("Theme", selection: $theme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel(accent: .indigo)
    }

    private var aboutPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About").font(.headline)
            LabeledContent("Version", value: AppIdentity.version)
            LabeledContent("Platforms", value: "iOS 27 · macOS 27")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel(accent: .cyan)
    }

}
