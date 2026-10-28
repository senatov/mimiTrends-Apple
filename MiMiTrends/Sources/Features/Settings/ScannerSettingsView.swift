import SwiftUI

struct ScannerSettingsView: View {
    @AppStorage("radar.historyLimit.v1") private var maxResults = 30
    @AppStorage("radar.historyAgeHours.v1") private var maxAgeHours = 2
    @AppStorage("radar.scanWatchlist.v1") private var scanWatchlist = false

    var body: some View {
        SettingsPage(title: "Scanner", subtitle: "Current radar scope and saved results") { width in
            if width >= 900 {
                HStack(alignment: .top, spacing: 18) {
                    resultPanel
                    scopePanel
                }
            } else {
                resultPanel
                scopePanel
            }
        }
    }

    private var resultPanel: some View {
        SettingsGroup(title: "Saved signal display") {
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
    }

    private var scopePanel: some View {
        SettingsGroup(title: "Current scan scope") {
            LabeledContent("Source", value: "Finnhub live trades")
            LabeledContent("Symbols", value: scanWatchlist ? "Selected + Watchlist, up to 5" : "Selected symbol")
            LabeledContent("Activity", value: "Foreground only")
            Text("Desktop market universes, statistical anomaly filters, scan intervals, and currency conversion require their native scanner and source adapters before they can be configured here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
