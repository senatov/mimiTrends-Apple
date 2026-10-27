import SwiftUI

struct RadarHeader: View {
    @Binding var symbol: String
    let session: RadarSession
    let setupMessage: String?
    let onToggleFeed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("MiMiTrends")
                    .font(.title2.weight(.semibold))
                Spacer(minLength: 8)
                Label(statusText, systemImage: session.isSubscribed ? "checkmark.circle.fill" : "circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(session.isSubscribed ? .green : .secondary)
                    .accessibilityLabel("Finnhub: \(statusText)")
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { feedControls }
                VStack(alignment: .leading, spacing: 10) { feedControls }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) { sessionMetrics }
                VStack(alignment: .leading, spacing: 5) { sessionMetrics }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if let message = setupMessage ?? session.errorMessage {
                Text(message).font(.footnote).foregroundStyle(.red)
            }
        }
        .trendsPanel()
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

    @ViewBuilder
    private var sessionMetrics: some View {
        Label("\(session.tradeCount) trades", systemImage: "chart.line.uptrend.xyaxis")
        Label("\(session.completedBarsStored) bars saved", systemImage: "chart.bar")
        Text("One-symbol foreground scan")
    }
}
