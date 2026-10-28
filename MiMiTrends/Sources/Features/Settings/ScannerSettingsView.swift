import SwiftUI

struct ScannerSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("radar.historyLimit.v1") private var maxResults = 30
    @AppStorage("radar.historyAgeHours.v1") private var maxAgeHours = 2

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Scanner").font(.title2.weight(.semibold))
                    Text("Current radar scope and saved results")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                resultPanel
                scopePanel
            }
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .background(TrendsColors.canvas(colorScheme))
        .navigationTitle(AppIdentity.windowTitle)
    }

    private var resultPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Saved signal display", systemImage: "list.bullet.rectangle")
                .font(.headline)
            Stepper(value: $maxResults, in: 5...100, step: 5) {
                LabeledContent("Maximum results", value: maxResults.formatted())
            }
            .accessibilityLabel("Maximum results")
            Stepper(value: $maxAgeHours, in: 1...72) {
                LabeledContent("Maximum signal age", value: "\(maxAgeHours) h")
            }
            .accessibilityLabel("Maximum signal age")
            Text("These limits filter the saved Radar list on this device. They do not delete signals from the database.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel(accent: .blue)
    }

    private var scopePanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Current scan scope", systemImage: "scope")
                .font(.headline)
            LabeledContent("Source", value: "Finnhub live trades")
            LabeledContent("Symbols", value: "One selected symbol")
            LabeledContent("Activity", value: "Foreground only")
            Text("Desktop market universes, statistical anomaly filters, scan intervals, and currency conversion require their native scanner and source adapters before they can be configured here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel(accent: .teal)
    }
}
