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
                if !isCompactLayout { Spacer(minLength: 8) }
                scopePicker
            }
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
}
