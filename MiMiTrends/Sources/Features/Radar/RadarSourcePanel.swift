import SwiftUI

struct RadarSourcePanel: View {
    let session: RadarSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sources").font(.headline)
            Divider()
            HStack {
                Text("Finnhub").fontWeight(.medium)
                Spacer()
                Text(statusText)
                    .foregroundStyle(session.isSubscribed ? .green : .secondary)
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
