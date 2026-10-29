import SwiftUI

struct RadarSourcePanel: View {
    let session: RadarSession
    let discoveryStatus: DiscoveryRefreshStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Source telemetry").font(.headline)
                Spacer(minLength: 8)
                Text("Current session")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
            HStack(spacing: 7) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text("Finnhub").font(.subheadline.weight(.semibold))
                Spacer(minLength: 4)
                Text(statusText.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(statusColor)
            }
            HStack(spacing: 0) {
                metric("RECEIVED", value: session.tradeCount)
                metric("BARS", value: session.completedBarsStored)
                metric("SIGNALS", value: session.signalCount)
                metric("ERRORS", value: session.errorCount)
            }
            if let trade = session.lastTrade {
                Text("Last trade: \(trade.symbol) · \(trade.price.formatted()) · \(Date(timeIntervalSince1970: TimeInterval(trade.timestampMillis) / 1_000), style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let error = session.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
            Divider()
            HStack(spacing: 7) {
                Circle()
                    .fill(discoveryStatus?.hasFreshSnapshot(atMillis: Int64(Date().timeIntervalSince1970 * 1_000)) == true ? .green : .secondary)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text("miminavi.tech · info1")
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 4)
                if let snapshot = discoveryStatus?.snapshot {
                    NavigationLink {
                        DiscoveryCandidateList(snapshot: snapshot)
                    } label: {
                        Image(systemName: "list.number")
                    }
                    .buttonStyle(TrendsActionButtonStyle(compact: true))
                    .accessibilityLabel("View ranking candidates")
                    .help("View ranking candidates")
                }
                Text(discoveryLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(discoveryDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .trendsPanel()
    }

    private var discoveryLabel: String {
        guard let discoveryStatus else { return "CONNECTING" }
        if discoveryStatus.hasFreshSnapshot(atMillis: Int64(Date().timeIntervalSince1970 * 1_000)) {
            return "CURRENT"
        }
        return discoveryStatus.isAvailable ? "SAVED" : "UNAVAILABLE"
    }

    private var discoveryDetail: String {
        guard let discoveryStatus else { return "Loading ranking candidates…" }
        guard let snapshot = discoveryStatus.snapshot else { return "Ranking data unavailable." }
        return "\(snapshot.candidates.count) candidates · ticker mapping pending"
    }

    private func metric(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value.formatted())
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var statusText: String {
        if session.isSubscribed { return "Online" }
        if session.isScanning { return "Connecting" }
        if session.errorMessage != nil { return "Attention" }
        return "Stopped"
    }

    private var statusColor: Color {
        if session.isSubscribed { return .green }
        if session.errorMessage != nil { return .orange }
        return .secondary
    }
}
