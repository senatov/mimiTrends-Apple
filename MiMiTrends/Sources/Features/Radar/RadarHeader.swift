import SwiftUI

struct RadarHeader: View {
    @Binding var symbol: String
    let session: RadarSession
    let setupMessage: String?
    let onToggleFeed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    feedControls
                    statusLabel
                    Spacer(minLength: 8)
                    metricStrip
                }
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 10) { feedControls }
                    HStack(spacing: 8) {
                        statusLabel
                        Spacer(minLength: 4)
                        metricStrip
                    }
                }
            }
            if let message = setupMessage ?? session.errorMessage {
                Text(message).font(.footnote).foregroundStyle(.red)
            }
        }
        .trendsPanel(accent: .cyan)
    }

    @ViewBuilder
    private var feedControls: some View {
        TextField("Ticker symbol", text: $symbol)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .frame(maxWidth: 240)
            .accessibilityLabel("Radar symbol")
        TrendsActionButton(
            title: session.isScanning ? "Stop feed" : "Start feed",
            systemImage: session.isScanning ? "stop.fill" : "play.fill",
            tint: session.isScanning ? .red : .green
        ) { onToggleFeed() }
        .disabled(!session.isScanning && symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var statusText: String {
        if session.isSubscribed { return "Connected" }
        if session.isScanning { return "Connecting" }
        return "Stopped"
    }

    private var statusLabel: some View {
        Label(statusText, systemImage: session.isSubscribed ? "checkmark.circle.fill" : "circle.fill")
            .font(.caption.weight(.medium))
            .foregroundStyle(session.isSubscribed ? .green : .secondary)
            .accessibilityLabel("Finnhub: \(statusText)")
    }

    private var metricStrip: some View {
        HStack(spacing: 10) {
            Label("\(session.tradeCount) trades", systemImage: "chart.line.uptrend.xyaxis")
            Label("\(session.completedBarsStored) bars", systemImage: "chart.bar")
            Text("Foreground · 1 symbol")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}
