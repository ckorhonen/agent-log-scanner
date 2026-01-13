import Foundation

class ClaudeMDManager {
    private let fileManager = FileManager.default

    private var globalCLAUDEMDPath: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
            .appendingPathComponent("CLAUDE.md")
    }

    func readGlobalCLAUDEMD() -> String? {
        try? String(contentsOf: globalCLAUDEMDPath, encoding: .utf8)
    }

    func readProjectCLAUDEMD(projectPath: String) -> String? {
        // Decode the project path
        let decodedPath = "/" + projectPath.replacingOccurrences(of: "-", with: "/")
        let claudeMDPath = URL(fileURLWithPath: decodedPath).appendingPathComponent("CLAUDE.md")

        return try? String(contentsOf: claudeMDPath, encoding: .utf8)
    }

    func appendToGlobalCLAUDEMD(_ content: String) {
        appendToFile(at: globalCLAUDEMDPath, content: content)
    }

    func appendToProjectCLAUDEMD(projectPath: String, content: String) {
        let decodedPath = "/" + projectPath.replacingOccurrences(of: "-", with: "/")
        let claudeMDPath = URL(fileURLWithPath: decodedPath).appendingPathComponent("CLAUDE.md")

        appendToFile(at: claudeMDPath, content: content)
    }

    private func appendToFile(at url: URL, content: String) {
        let formattedContent = "\n\n" + content

        if fileManager.fileExists(atPath: url.path) {
            // Append to existing file
            if let fileHandle = try? FileHandle(forWritingTo: url) {
                fileHandle.seekToEndOfFile()
                if let data = formattedContent.data(using: .utf8) {
                    fileHandle.write(data)
                }
                try? fileHandle.close()
            }
        } else {
            // Create new file with header
            let header = "# CLAUDE.md\n\nThis file contains instructions for Claude Code.\n"
            let fullContent = header + formattedContent
            try? fullContent.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    func projectCLAUDEMDExists(projectPath: String) -> Bool {
        let decodedPath = "/" + projectPath.replacingOccurrences(of: "-", with: "/")
        let claudeMDPath = URL(fileURLWithPath: decodedPath).appendingPathComponent("CLAUDE.md")
        return fileManager.fileExists(atPath: claudeMDPath.path)
    }
}
