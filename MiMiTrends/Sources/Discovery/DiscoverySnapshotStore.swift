import Foundation

actor DiscoverySnapshotStore {
    private let url: URL

    init(url: URL) {
        self.url = url
    }

    static func defaultURL(for sourceID: String) throws -> URL {
        guard sourceID.range(of: "^[A-Za-z0-9_-]{1,64}$", options: .regularExpression) != nil else {
            throw DiscoveryDataError.invalidSnapshot
        }
        return try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        ).appendingPathComponent("discovery-\(sourceID).json")
    }

    func load() throws -> DiscoverySnapshot? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let snapshot = try JSONDecoder().decode(DiscoverySnapshot.self, from: Data(contentsOf: url))
            try snapshot.validate()
            return snapshot
        } catch {
            throw DiscoveryDataError.invalidSnapshot
        }
    }

    func save(_ snapshot: DiscoverySnapshot) throws {
        try snapshot.validate()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
    }
}
