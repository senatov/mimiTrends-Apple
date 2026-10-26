import SwiftUI

@main
struct MiMiTrendsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var radarSession = RadarSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(radarSession)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                radarSession.stop()
            }
        }
    }
}
