import Foundation

enum DiscoveryCandidateSelector {
    static let maximumInputRows = 1_000
    static let maximumCandidates = maximumInputRows

    static func select(_ input: [DiscoveryCandidate], sourceID: String) throws -> [DiscoveryCandidate] {
        guard input.count <= maximumInputRows,
              !sourceID.isEmpty,
              input.allSatisfy({ $0.sourceID == sourceID }) else {
            throw DiscoveryDataError.invalidCandidate
        }
        for candidate in input { try candidate.validate() }

        let groups = DiscoveryCategory.selectionOrder.map { category in
            input.filter { $0.category == category }
                .sorted {
                    if $0.rank != $1.rank { return $0.rank < $1.rank }
                    return $0.instrumentID < $1.instrumentID
                }
        }
        var selected: [DiscoveryCandidate] = []
        var seen = Set<String>()
        var rank = 0
        while groups.contains(where: { rank < $0.count }) {
            for group in groups where rank < group.count {
                let candidate = group[rank]
                if seen.insert(candidate.identity).inserted {
                    selected.append(candidate)
                }
            }
            rank += 1
        }
        return selected
    }
}
