import SwiftUI

struct RadarView: View {
    @Environment(RadarSession.self) private var session

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Live Radar", systemImage: "waveform.path.ecg")
            } description: {
                Text("Market scanning will be added in a later stage. The scanner will stop when the app leaves the foreground.")
            }
            .navigationTitle("Radar")
            .toolbar {
                ToolbarItem(placement: .status) {
                    Text(session.isScanning ? "Scanning" : "Scanner offline")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
