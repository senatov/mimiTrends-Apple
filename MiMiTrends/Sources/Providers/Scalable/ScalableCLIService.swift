#if os(macOS)
import Foundation

enum ScalableCLIError: LocalizedError {
    case notInstalled
    case loginRequired
    case commandFailed
    case timedOut

    var errorDescription: String? {
        switch self {
        case .notInstalled: "Scalable CLI is not installed."
        case .loginRequired: "Scalable login is required."
        case .commandFailed: "Scalable CLI could not complete the request."
        case .timedOut: "Scalable CLI did not respond in time."
        }
    }
}

struct ScalableCLIService: Sendable {
    func isAuthorized() async throws -> Bool {
        let executable = try Self.executableURL()
        return try await Task.detached(priority: .utility) {
            let data = try Self.run(executable, arguments: ["whoami", "--json"])
            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ScalableCLIError.commandFailed
            }
            return root["ok"] as? Bool == true
        }.value
    }

    func startReadOnlyLogin() async throws {
        let executable = try Self.executableURL()
        try await Task.detached(priority: .utility) {
            let script = try Self.makeLoginScript(executable: executable)
            _ = try Self.run(URL(fileURLWithPath: "/usr/bin/open"),
                             arguments: ["-a", "Terminal", script.path])
        }.value
    }

    private static func executableURL() throws -> URL {
        let paths = ["/opt/homebrew/bin/sc", "/usr/local/bin/sc"] +
            (ProcessInfo.processInfo.environment["PATH"] ?? "")
                .split(separator: ":").map { "\($0)/sc" }
        guard let path = paths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            throw ScalableCLIError.notInstalled
        }
        return URL(fileURLWithPath: path)
    }

    private static func makeLoginScript(executable: URL) throws -> URL {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimitrends-scalable-login-\(UUID().uuidString).command")
        let quoted = "'" + executable.path.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
        let source = """
        #!/bin/zsh
        log_file=$(mktemp -t mimitrends-scalable-login)
        trap 'rm -f "$log_file" "$0"' EXIT
        \(quoted) login --local-read-only >"$log_file" 2>&1 &
        login_pid=$!
        for attempt in {1..30}; do
          activate_url=$(grep -Eo 'https://secure\\.scalable\\.capital/activate[^ )]+' "$log_file" | head -1)
          if [[ -n "$activate_url" ]]; then
            open "$activate_url"
            break
          fi
          sleep 1
        done
        wait "$login_pid"
        result=$?
        cat "$log_file"
        echo
        if (( result == 0 )); then
          echo 'Scalable login complete. MiMiTrends will check the session automatically.'
        else
          echo 'Scalable login did not complete. Retry from MiMiTrends.'
        fi
        exit "$result"
        """
        try source.write(to: path, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: path.path)
        return path
    }

    private static func run(_ executable: URL, arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()
        try process.run()
        let deadline = Date().addingTimeInterval(10)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        guard !process.isRunning else {
            process.terminate()
            throw ScalableCLIError.timedOut
        }
        guard process.terminationStatus == 0 else { throw ScalableCLIError.commandFailed }
        return output.fileHandleForReading.readDataToEndOfFile()
    }
}
#endif
