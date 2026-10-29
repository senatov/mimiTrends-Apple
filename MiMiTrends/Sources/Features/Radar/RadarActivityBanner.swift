import SwiftUI

enum RadarActivity: Equatable {
    case loadingRankings(previousCount: Int?)
    case preparingFeed
    case connectingFeed(symbolCount: Int)

    var title: String {
        switch self {
        case .loadingRankings: "Collecting ranking candidates…"
        case .preparingFeed: "Preparing live feed…"
        case .connectingFeed: "Connecting to Finnhub…"
        }
    }

    var detail: String {
        switch self {
        case .loadingRankings(let previousCount):
            if let previousCount { "\(previousCount) saved candidates remain available" }
            else { "Fetching the current market ranking" }
        case .preparingFeed:
            "Loading the selected symbols and scan settings"
        case .connectingFeed(let symbolCount):
            "Requesting live trades for \(symbolCount) \(symbolCount == 1 ? "symbol" : "symbols")"
        }
    }
}

struct RadarActivityBanner: View {
    let activity: RadarActivity

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline.weight(.semibold))
                Text(activity.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trendsPanel()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(activity.title) \(activity.detail)")
    }
}
