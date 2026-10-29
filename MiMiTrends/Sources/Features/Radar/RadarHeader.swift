import SwiftUI

struct RadarHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @Binding var symbol: String
    @Binding var scanWatchlist: Bool
    let session: RadarSession
    let setupMessage: String?
    let isPreparingFeed: Bool
    let onToggleFeed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            headerLayout {
                HStack(spacing: 10) { feedControls }
                statusLabel
                if !isCompactLayout { Spacer(minLength: 8) }
                metricStrip
            }
            scopePicker
                .frame(maxWidth: .infinity, alignment: .leading)
            if let message = setupMessage ?? session.errorMessage {
                Text(message).font(.footnote).foregroundStyle(.red)
            }
        }
        .trendsPanel()
    }

    private var isCompactLayout: Bool {
        #if os(iOS)
        dynamicTypeSize.isAccessibilitySize || horizontalSizeClass == .compact
        #else
        dynamicTypeSize.isAccessibilitySize
        #endif
    }

    private func headerLayout<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let layout = isCompactLayout
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 7))
            : AnyLayout(HStackLayout(spacing: 10))
        return layout { content() }
    }

    @ViewBuilder
    private var feedControls: some View {
        TextField("Ticker symbol", text: $symbol)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .frame(maxWidth: 240)
            .accessibilityLabel("Radar symbol")
        TrendsActionButton(
            title: session.isScanning ? "Stop feed" : isPreparingFeed ? "Preparing" : "Start feed",
            systemImage: session.isScanning ? "stop.fill" : "play.fill",
            tint: session.isScanning ? .red : .green
        ) { onToggleFeed() }
        .disabled(isPreparingFeed || (!session.isScanning && symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
    }

    private var scopePicker: some View {
        Picker("Scan scope", selection: $scanWatchlist) {
            Text("Selected").tag(false)
            Text("Selected + Watchlist").tag(true)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(maxWidth: 310)
        .disabled(session.isScanning || isPreparingFeed)
        .help("Selected + Watchlist requests at most five symbols per feed.")
    }

    private var statusText: String {
        if session.isSubscribed { return session.tradeCount > 0 ? "Receiving trades" : "Waiting for trades" }
        if session.isScanning { return "Connecting" }
        return "Stopped"
    }

    private var statusLabel: some View {
        Label("Finnhub · \(statusText)", systemImage: session.tradeCount > 0 ? "checkmark.circle.fill" : "circle.fill")
            .font(.caption.weight(.medium))
            .foregroundStyle(session.tradeCount > 0 ? .green : .secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
            .accessibilityLabel("Finnhub: \(statusText)")
    }

    private var metricStrip: some View {
        HStack(spacing: 10) {
            Label("\(session.tradeCount) trades", systemImage: "chart.line.uptrend.xyaxis")
            Label("\(session.completedBarsStored) bars", systemImage: "chart.bar")
            Text("\(session.isScanning ? session.targetSymbols.count : 1) requested · foreground only")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .lineLimit(1)
    }
}
