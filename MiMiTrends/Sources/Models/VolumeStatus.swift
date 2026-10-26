enum VolumeStatus: String, Codable, CaseIterable, Sendable {
    case reported = "REPORTED"
    case zero = "ZERO"
    case missing = "MISSING"
    case estimated = "ESTIMATED"

    var isReliable: Bool { self == .reported }

    static func aggregate(_ statuses: [VolumeStatus]) -> VolumeStatus {
        guard !statuses.isEmpty else { return .missing }
        if statuses.allSatisfy({ $0 == .reported }) { return .reported }
        if statuses.allSatisfy({ $0 == .zero }) { return .zero }
        if !statuses.contains(where: \.isReliable) && statuses.contains(.missing) { return .missing }
        return .estimated
    }
}
