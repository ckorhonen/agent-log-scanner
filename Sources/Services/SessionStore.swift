import Foundation

@Observable
class SessionStore {
    private(set) var sessions: [SessionSummary] = []
    private(set) var projects: [String] = []
    private(set) var isLoading = false
    private(set) var error: String?

    private let pageSize = 50
    private var allSessionFiles: [URL] = []
    private var loadedCount = 0

    var hasMoreSessions: Bool {
        loadedCount < allSessionFiles.count
    }

    private var claudeProjectsPath: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
            .appendingPathComponent("projects")
    }

    init() {
        Task {
            await loadSessions()
        }
    }

    @MainActor
    func loadSessions() async {
        // Prevent multiple simultaneous loads
        guard !isLoading else { return }

        isLoading = true
        error = nil
        sessions = []
        allSessionFiles = []
        loadedCount = 0

        do {
            allSessionFiles = try discoverSessionFiles()
            await loadMoreSessions()
            projects = extractUniqueProjects()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func loadMoreSessions() async {
        let startIndex = loadedCount
        let endIndex = min(loadedCount + pageSize, allSessionFiles.count)

        guard startIndex < endIndex else { return }

        let filesToLoad = Array(allSessionFiles[startIndex..<endIndex])

        // Collect new sessions first
        var newSessions: [SessionSummary] = []

        await withTaskGroup(of: SessionSummary?.self) { group in
            for file in filesToLoad {
                group.addTask {
                    await self.parseSessionSummary(from: file)
                }
            }

            for await summary in group {
                if let summary = summary {
                    newSessions.append(summary)
                }
            }
        }

        // Add only sessions that don't already exist (dedupe by file path)
        let existingPaths = Set(sessions.map { $0.filePath.path })
        for session in newSessions {
            if !existingPaths.contains(session.filePath.path) {
                sessions.append(session)
            }
        }

        // Sort by timestamp descending
        sessions.sort { $0.timestamp > $1.timestamp }
        loadedCount = endIndex
    }

    func loadFullSession(_ summary: SessionSummary) async throws -> Session {
        let messages = try await parseFullSession(from: summary.filePath)
        return Session(id: summary.id, projectPath: summary.projectPath, messages: messages)
    }

    private func discoverSessionFiles() throws -> [URL] {
        let fileManager = FileManager.default
        var sessionFiles: [URL] = []

        guard fileManager.fileExists(atPath: claudeProjectsPath.path) else {
            return []
        }

        let projectDirs = try fileManager.contentsOfDirectory(
            at: claudeProjectsPath,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for projectDir in projectDirs {
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: projectDir.path, isDirectory: &isDir),
                  isDir.boolValue else { continue }

            let files = try fileManager.contentsOfDirectory(
                at: projectDir,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            for file in files {
                // Only include .jsonl files that aren't agent sub-sessions
                if file.pathExtension == "jsonl" && !file.lastPathComponent.hasPrefix("agent-") {
                    sessionFiles.append(file)
                }
            }
        }

        // Sort by modification date (most recent first)
        sessionFiles.sort { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return date1 > date2
        }

        return sessionFiles
    }

    private func parseSessionSummary(from fileURL: URL) async -> SessionSummary? {
        do {
            let fileHandle = try FileHandle(forReadingFrom: fileURL)
            defer { try? fileHandle.close() }

            // Read first chunk to get metadata
            guard let data = try fileHandle.read(upToCount: 10000),
                  let content = String(data: data, encoding: .utf8) else {
                return nil
            }

            let lines = content.components(separatedBy: .newlines)

            var timestamp: Date?
            let projectPath = fileURL.deletingLastPathComponent().lastPathComponent

            for line in lines {
                guard !line.isEmpty,
                      let lineData = line.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                    continue
                }

                // Extract timestamp from first message
                if timestamp == nil, let timestampString = json["timestamp"] as? String {
                    timestamp = ISO8601DateFormatter().date(from: timestampString)
                    break // Only need first timestamp
                }
            }

            // If we couldn't read from content, use file attributes
            if timestamp == nil {
                let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                timestamp = attrs[.modificationDate] as? Date ?? Date()
            }

            guard let finalTimestamp = timestamp else {
                return nil
            }

            // Count all turns in file for accurate count
            let fullContent = try String(contentsOf: fileURL, encoding: .utf8)
            let allLines = fullContent.components(separatedBy: .newlines)
            var fullTurnCount = 0
            for line in allLines {
                if line.contains("\"type\":\"user\"") {
                    fullTurnCount += 1
                }
            }

            return SessionSummary(
                projectPath: projectPath,
                projectName: Session.extractProjectName(from: projectPath),
                timestamp: finalTimestamp,
                turnCount: fullTurnCount,
                filePath: fileURL
            )
        } catch {
            print("Error parsing session summary: \(error)")
            return nil
        }
    }

    private func parseFullSession(from fileURL: URL) async throws -> [Message] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var messages: [Message] = []

        for line in lines {
            guard !line.isEmpty,
                  let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }

            guard let type = json["type"] as? String,
                  (type == "user" || type == "assistant") else {
                continue
            }

            guard let messageData = json["message"] as? [String: Any],
                  let roleString = messageData["role"] as? String,
                  let contentArray = messageData["content"] as? [[String: Any]] else {
                continue
            }

            let role: MessageRole = roleString == "user" ? .user : .assistant

            var contentBlocks: [ContentBlock] = []

            for contentItem in contentArray {
                if let blockType = contentItem["type"] as? String {
                    switch blockType {
                    case "text":
                        if let text = contentItem["text"] as? String {
                            contentBlocks.append(.text(text))
                        }
                    case "tool_use":
                        if let id = contentItem["id"] as? String,
                           let name = contentItem["name"] as? String,
                           let input = contentItem["input"] as? [String: Any] {
                            contentBlocks.append(.toolUse(ToolCall(id: id, name: name, input: input)))
                        }
                    case "tool_result":
                        if let toolUseId = contentItem["tool_use_id"] as? String {
                            let resultContent: String
                            if let content = contentItem["content"] as? String {
                                resultContent = content
                            } else if let contentArray = contentItem["content"] as? [[String: Any]] {
                                resultContent = contentArray.compactMap { $0["text"] as? String }.joined(separator: "\n")
                            } else {
                                resultContent = ""
                            }
                            let isError = contentItem["is_error"] as? Bool ?? false
                            contentBlocks.append(.toolResult(ToolResult(
                                id: UUID().uuidString,
                                toolUseId: toolUseId,
                                content: resultContent,
                                isError: isError
                            )))
                        }
                    default:
                        break
                    }
                }
            }

            // Skip empty messages
            guard !contentBlocks.isEmpty else { continue }

            let uuid: UUID
            if let uuidString = json["uuid"] as? String, let parsed = UUID(uuidString: uuidString) {
                uuid = parsed
            } else {
                uuid = UUID()
            }

            let parentUuid: UUID?
            if let parentString = json["parentUuid"] as? String {
                parentUuid = UUID(uuidString: parentString)
            } else {
                parentUuid = nil
            }

            let timestamp: Date
            if let timestampString = json["timestamp"] as? String,
               let parsed = ISO8601DateFormatter().date(from: timestampString) {
                timestamp = parsed
            } else {
                timestamp = Date()
            }

            messages.append(Message(
                id: uuid,
                role: role,
                content: contentBlocks,
                timestamp: timestamp,
                parentId: parentUuid
            ))
        }

        return messages
    }

    private func extractUniqueProjects() -> [String] {
        let projectSet = Set(sessions.map { $0.projectName })
        return projectSet.sorted()
    }

    func filteredSessions(by projectName: String?) -> [SessionSummary] {
        guard let projectName = projectName else {
            return sessions
        }
        return sessions.filter { $0.projectName == projectName }
    }
}
