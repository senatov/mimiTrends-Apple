import Foundation

struct DiscoveryRankingRow: Equatable, Sendable {
    let instrumentID: String
    let rank: Int
    let resolved: ResolvedMarketSymbol?
    let displayName: String?

    init(instrumentID: String, rank: Int, resolved: ResolvedMarketSymbol?, displayName: String? = nil) {
        self.instrumentID = instrumentID
        self.rank = rank
        self.resolved = resolved
        self.displayName = displayName
    }
}

struct DiscoveryRankingBatch: Sendable {
    static let maximumRows = 50

    let origin: DiscoveryRankingOrigin
    let observedAtMillis: Int64
    let rows: [DiscoveryRankingRow]

    func candidates(sourceID: String) throws -> [DiscoveryCandidate] {
        guard origin.period.isValid(for: origin.page), observedAtMillis > 0,
              rows.count <= Self.maximumRows,
              Set(rows.map(\.rank)).count == rows.count,
              rows.allSatisfy({ (1...Self.maximumRows).contains($0.rank) }) else {
            throw DiscoveryDataError.invalidCandidate
        }
        return try rows.map { row in
            let candidate = DiscoveryCandidate(
                sourceID: sourceID, instrumentID: row.instrumentID,
                category: origin.page.category, rank: row.rank,
                observedAtMillis: observedAtMillis, resolved: row.resolved,
                origin: origin, displayName: row.displayName
            )
            try candidate.validate()
            return candidate
        }
    }
}

struct DiscoveryRankingAssembly: Sendable {
    let candidates: [DiscoveryCandidate]
    let availableRankings: Set<DiscoveryRankingKey>
    let emptyRankings: Set<DiscoveryRankingKey>
}

struct DiscoveryRankingKey: Hashable, Sendable {
    let page: DiscoveryRankingPage
    let period: DiscoveryRankingPeriod
}

enum DiscoveryRankingAssembler {
    static func assemble(_ batches: [DiscoveryRankingBatch], sourceID: String) throws -> DiscoveryRankingAssembly {
        guard !batches.isEmpty,
              batches.count <= DiscoveryRankingPage.allCases.count * 4 else {
            throw DiscoveryDataError.invalidCandidate
        }
        var keys = Set<DiscoveryRankingKey>()
        var empty = Set<DiscoveryRankingKey>()
        var rows: [DiscoveryCandidate] = []
        for batch in batches {
            let key = DiscoveryRankingKey(page: batch.origin.page, period: batch.origin.period)
            guard keys.insert(key).inserted else { throw DiscoveryDataError.invalidCandidate }
            if batch.rows.isEmpty { empty.insert(key) }
            rows.append(contentsOf: try batch.candidates(sourceID: sourceID))
        }
        return DiscoveryRankingAssembly(
            candidates: try DiscoveryCandidateSelector.select(rows, sourceID: sourceID),
            availableRankings: keys, emptyRankings: empty
        )
    }
}
