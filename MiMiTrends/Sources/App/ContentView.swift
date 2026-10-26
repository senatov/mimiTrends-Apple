import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Radar", systemImage: "waveform.path.ecg") {
                RadarView()
            }

            Tab("Watchlist", systemImage: "star") {
                WatchlistView()
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}
