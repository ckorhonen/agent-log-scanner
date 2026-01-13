import Foundation

/// Persists and retrieves session analysis results
actor AnalysisStore {
    private let fileManager = FileManager.default

    private var appSupportURL: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("AgentLogScanner", isDirectory: true)

        // Create directory if needed
        if !fileManager.fileExists(atPath: appSupport.path) {
            try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        return appSupport
    }

    private var analysesDirectory: URL {
        let dir = appSupportURL.appendingPathComponent("analyses", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Generate a stable filename for a session's analysis based on its file path
    private func analysisFilename(for sessionFilePath: URL) -> String {
        // Use a hash of the session file path for a stable, filesystem-safe name
        let pathHash = sessionFilePath.path.data(using: .utf8)!
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .prefix(64)
        return "\(pathHash).json"
    }

    /// Save analysis results for a session
    func save(suggestions: [AnalysisSuggestion], for sessionFilePath: URL) throws {
        let filename = analysisFilename(for: sessionFilePath)
        let fileURL = analysesDirectory.appendingPathComponent(filename)

        let wrapper = AnalysisWrapper(
            sessionFilePath: sessionFilePath.path,
            analyzedAt: Date(),
            suggestions: suggestions
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(wrapper)
        try data.write(to: fileURL)
    }

    /// Load analysis results for a session, if they exist
    func load(for sessionFilePath: URL) -> AnalysisWrapper? {
        let filename = analysisFilename(for: sessionFilePath)
        let fileURL = analysesDirectory.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(AnalysisWrapper.self, from: data)
    }

    /// Check if analysis exists for a session
    func hasAnalysis(for sessionFilePath: URL) -> Bool {
        let filename = analysisFilename(for: sessionFilePath)
        let fileURL = analysesDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Delete analysis for a session (for re-analysis)
    func delete(for sessionFilePath: URL) throws {
        let filename = analysisFilename(for: sessionFilePath)
        let fileURL = analysesDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
}

/// Wrapper for persisted analysis data
struct AnalysisWrapper: Codable {
    let sessionFilePath: String
    let analyzedAt: Date
    let suggestions: [AnalysisSuggestion]
}
