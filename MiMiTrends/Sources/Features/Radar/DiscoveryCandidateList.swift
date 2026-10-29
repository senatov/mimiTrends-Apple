import SwiftUI

struct DiscoveryCandidateList: View {
    let snapshot: DiscoverySnapshot
    @State private var searchText = ""

    var body: some View {
        List {
            Section {
                Text("These rankings identify companies, but do not supply verified Finnhub symbols. Ranking candidates are not scanned yet.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("Last fetch: \(Date(timeIntervalSince1970: TimeInterval(snapshot.refreshedAtMillis) / 1_000), style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("\(filteredCandidates.count) candidates") {
                ForEach(filteredCandidates, id: \.identity) { candidate in
                    candidateRow(candidate)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Company or instrument path")
        .navigationTitle("Ranking candidates")
    }

    private var filteredCandidates: [DiscoveryCandidate] {
        guard !searchText.isEmpty else { return snapshot.candidates }
        return snapshot.candidates.filter {
            ($0.displayName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                $0.instrumentID.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func candidateRow(_ candidate: DiscoveryCandidate) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(candidate.displayName ?? candidate.instrumentID)
                .font(.body.weight(.medium))
            HStack(spacing: 8) {
                Text("#\(candidate.rank) · \(periodLabel(candidate.origin?.period))")
                Text(candidate.instrumentID)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func periodLabel(_ period: DiscoveryRankingPeriod?) -> String {
        switch period {
        case .day: "1 day"
        case .week: "7 days"
        case .month: "30 days"
        case .year: "1 year"
        case .activity: "Activity"
        case nil: "Saved ranking"
        }
    }
}
