import Foundation

enum MiminaviInfo1Decoder {
    static let maximumBytes = 512_000
    private static let expectedSource = "https://www.wallstreet-online.de/statistik/top-aktien-performance"

    static func decode(_ data: Data, sourceID: String, nowMillis: Int64) throws -> [DiscoveryCandidate] {
        guard !data.isEmpty, data.count <= maximumBytes else { throw DiscoveryDataError.invalidCandidate }
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        guard payload.source == expectedSource else { throw DiscoveryDataError.invalidCandidate }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let generatedAt = formatter.date(from: payload.generatedAt) else {
            throw DiscoveryDataError.invalidCandidate
        }
        let observedAt = Int64(generatedAt.timeIntervalSince1970 * 1_000)
        let age = nowMillis - observedAt
        guard observedAt > 0, age >= -5 * 60_000, age <= 30 * 60_000 else {
            throw DiscoveryDataError.invalidCandidate
        }

        let periods: [(DiscoveryRankingPeriod, [Row])] = [
            (.day, payload.periods.day), (.week, payload.periods.week),
            (.month, payload.periods.month), (.year, payload.periods.year)
        ]
        let batches = try periods.map { period, rows in
            DiscoveryRankingBatch(
                origin: DiscoveryRankingOrigin(page: .allIndices, period: period),
                observedAtMillis: observedAt,
                rows: try rows.map { row in
                    guard !row.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          row.price.isFinite, row.price > 0,
                          row.performance1dPercent.isFinite,
                          row.performance7dPercent.isFinite,
                          row.performance30dPercent.isFinite,
                          row.performance1yPercent.isFinite,
                          let url = URL(string: row.url),
                          url.scheme == "https", url.host == "www.wallstreet-online.de",
                          url.user == nil, url.password == nil,
                          url.port == nil, url.query == nil, url.fragment == nil,
                          url.path.range(of: "^/aktien/[a-z0-9]+(-[a-z0-9]+)*$", options: .regularExpression) != nil else {
                        throw DiscoveryDataError.invalidCandidate
                    }
                    return DiscoveryRankingRow(
                        instrumentID: url.path, rank: row.rank, resolved: nil,
                        displayName: row.name.trimmingCharacters(in: .whitespacesAndNewlines),
                        marketMetrics: DiscoveryMarketMetrics(
                            price: row.price,
                            change1dPercent: row.performance1dPercent,
                            change7dPercent: row.performance7dPercent,
                            change30dPercent: row.performance30dPercent,
                            change1yPercent: row.performance1yPercent
                        )
                    )
                }
            )
        }
        return try DiscoveryRankingAssembler.assemble(batches, sourceID: sourceID).candidates
    }
}

private struct Payload: Decodable {
    let source: String
    let generatedAt: String
    let periods: Periods
}

private struct Periods: Decodable {
    let day: [Row]
    let week: [Row]
    let month: [Row]
    let year: [Row]

    enum CodingKeys: String, CodingKey {
        case day = "1d", week = "7d", month = "30d", year = "1y"
    }
}

private struct Row: Decodable {
    let rank: Int
    let name: String
    let url: String
    let price: Double
    let performance1dPercent: Double
    let performance7dPercent: Double
    let performance30dPercent: Double
    let performance1yPercent: Double
}
