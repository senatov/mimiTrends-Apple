import Foundation

enum DiscoveryRankingPage: String, Codable, CaseIterable, Sendable {
    case allIndices = "top-aktien-performance"
    case dax = "top-dax-aktien-performance"
    case cdax = "top-cdax-aktien-performance"
    case mdax = "top-mdax-aktien-performance"
    case tecdax = "top-tecdax-aktien-performance"
    case sdax = "top-sdax-aktien-performance"
    case eurozone50 = "top-eurostoxx-aktien-performance"
    case us30 = "top-dowjones-aktien-performance"
    case usTech100 = "top-nasdaq100-aktien-performance"
    case us500 = "top-sp500-aktien-performance"
    case trending = "trending-stocks"

    var path: String { "/statistik/\(rawValue)" }
    var category: DiscoveryCategory { self == .trending ? .trending : .top }
    var isIndexRanking: Bool { self != .trending }
}

enum DiscoveryRankingPeriod: String, Codable, CaseIterable, Sendable {
    case day, week, month, year, activity

    func isValid(for page: DiscoveryRankingPage) -> Bool {
        page.isIndexRanking ? self != .activity : self == .activity
    }
}

struct DiscoveryRankingOrigin: Codable, Equatable, Sendable {
    let page: DiscoveryRankingPage
    let period: DiscoveryRankingPeriod
}
