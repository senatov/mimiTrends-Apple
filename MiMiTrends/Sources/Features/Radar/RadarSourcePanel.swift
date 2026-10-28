import SwiftUI

struct RadarSourcePanel: View {
    let session: RadarSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sources").font(.headline)
            Divider()
            HStack(spacing: 8) {
                Text("Source").frame(maxWidth: .infinity, alignment: .leading)
                Text("Last").frame(width: 75, alignment: .trailing)
                Text("Trades").frame(width: 45, alignment: .trailing)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            Divider()
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Finnhub").fontWeight(.medium)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(session.isSubscribed ? .green : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let trade = session.lastTrade {
                    Text(Date(timeIntervalSince1970: TimeInterval(trade.timestampMillis) / 1_000), style: .relative)
                        .lineLimit(1)
                        .frame(width: 75, alignment: .trailing)
                } else {
                    Text("—").frame(width: 75, alignment: .trailing)
                }
                Text(session.tradeCount.formatted())
                    .monospacedDigit()
                    .frame(width: 45, alignment: .trailing)
            }
            .font(.subheadline)
            if let trade = session.lastTrade {
                LabeledContent("Last trade", value: "\(trade.symbol) · \(trade.price.formatted())")
                    .font(.subheadline)
            } else {
                Text("No trades received in this session.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Divider()
            Text("Only Finnhub trades are connected in this build. Other desktop sources are not yet available.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel()
    }

    private var statusText: String {
        if session.isSubscribed { return "Connected" }
        if session.isScanning { return "Connecting" }
        return "Stopped"
    }
}
