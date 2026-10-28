import SwiftUI

struct ContentView: View {
    @Environment(RadarSession.self) private var radarSession
    @AppStorage("selected.tab.v1") private var selectedTab = "radar"
    @AppStorage("selected.symbol.v1") private var radarSymbol = "ORCL"
    @AppStorage("appearance.theme.v1") private var theme = "light"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Radar", systemImage: "waveform.path.ecg", value: "radar") {
                RadarView(symbol: $radarSymbol)
            }

            Tab("Watchlist", systemImage: "star", value: "watchlist") {
                WatchlistView { symbol in
                    radarSession.stop()
                    radarSymbol = symbol
                    selectedTab = "radar"
                }
            }

            Tab("Chart", systemImage: "chart.xyaxis.line", value: "chart") {
                MarketChartView()
            }

            Tab("Settings", systemImage: "gearshape", value: "settings") {
                SettingsView()
            }
        }
        .preferredColorScheme(theme == "dark" ? .dark : theme == "light" ? .light : nil)
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .navigation) {
                HeaderBuildBadge()
            }
            ToolbarItem(placement: .automatic) {
                HeaderResourceBadges()
            }
            #endif
        }
    }
}
