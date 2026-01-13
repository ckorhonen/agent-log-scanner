import Foundation

/// Full session data for detail view
struct Session: Identifiable {
    let id: UUID
    let projectPath: String
    let projectName: String
    let messages: [Message]
    let stats: SessionStats

    init(id: UUID, projectPath: String, messages: [Message]) {
        self.id = id
        self.projectPath = projectPath
        self.projectName = Session.extractProjectName(from: projectPath)
        self.messages = messages
        self.stats = SessionStats(messages: messages)
    }

    static func extractProjectName(from path: String) -> String {
        // Path is encoded like: -Users-ckorhonen-Vault-Vault
        // Convert back to readable form and extract last component
        let decoded = path
            .replacingOccurrences(of: "-", with: "/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if let lastComponent = decoded.split(separator: "/").last {
            return String(lastComponent)
        }
        return path
    }
}

struct SessionStats {
    let humanMessageCount: Int
    let assistantMessageCount: Int
    let turnCount: Int
    let toolCallCount: Int
    let toolCallsByName: [String: Int]
    let duration: TimeInterval?
    let errorCount: Int

    init(messages: [Message]) {
        var human = 0
        var assistant = 0
        var toolCalls = 0
        var toolsByName: [String: Int] = [:]
        var errors = 0

        for message in messages {
            switch message.role {
            case .user:
                human += 1
            case .assistant:
                assistant += 1
            }

            for block in message.content {
                if case .toolUse(let tool) = block {
                    toolCalls += 1
                    toolsByName[tool.name, default: 0] += 1
                }
                if case .toolResult(let result) = block {
                    if result.isError {
                        errors += 1
                    }
                }
            }
        }

        self.humanMessageCount = human
        self.assistantMessageCount = assistant
        self.turnCount = human // Each user message is a "turn"
        self.toolCallCount = toolCalls
        self.toolCallsByName = toolsByName
        self.errorCount = errors

        // Calculate duration from first to last message
        if let first = messages.first?.timestamp,
           let last = messages.last?.timestamp {
            self.duration = last.timeIntervalSince(first)
        } else {
            self.duration = nil
        }
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }

        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }
}
