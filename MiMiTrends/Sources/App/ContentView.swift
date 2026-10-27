import SwiftUI

struct ContentView: View {
    @Environment(RadarSession.self) private var radarSession
    @State private var selectedTab: AppTab = .radar
    @State private var radarSymbol = "AAPL"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Radar", systemImage: "waveform.path.ecg", value: .radar) {
                RadarView(symbol: $radarSymbol)
            }

            Tab("Watchlist", systemImage: "star", value: .watchlist) {
                WatchlistView { symbol in
                    radarSession.stop()
                    radarSymbol = symbol
                    selectedTab = .radar
                }
            }

            Tab("Chart", systemImage: "chart.xyaxis.line", value: .chart) {
                MarketChartView()
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
    }
}

private enum AppTab: Hashable {
    case radar, watchlist, chart, settings
}
