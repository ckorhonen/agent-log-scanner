import Foundation

struct Message: Identifiable {
    let id: UUID
    let role: MessageRole
    let content: [ContentBlock]
    let timestamp: Date
    let parentId: UUID?

    /// Extract all text content concatenated
    var textContent: String {
        content.compactMap { block in
            if case .text(let text) = block {
                return text
            }
            return nil
        }.joined(separator: "\n")
    }

    /// Get all tool calls in this message
    var toolCalls: [ToolCall] {
        content.compactMap { block in
            if case .toolUse(let tool) = block {
                return tool
            }
            return nil
        }
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
}

enum ContentBlock: Identifiable {
    case text(String)
    case toolUse(ToolCall)
    case toolResult(ToolResult)

    var id: String {
        switch self {
        case .text(let text):
            return "text-\(text.hashValue)"
        case .toolUse(let tool):
            return "tool-\(tool.id)"
        case .toolResult(let result):
            return "result-\(result.toolUseId)"
        }
    }
}

struct ToolCall: Identifiable {
    let id: String
    let name: String
    let input: [String: Any]

    var inputSummary: String {
        // Create a brief summary of the input
        if let firstKey = input.keys.first {
            let value = input[firstKey]
            if let strValue = value as? String {
                let truncated = strValue.prefix(50)
                return "\(firstKey): \(truncated)\(strValue.count > 50 ? "..." : "")"
            }
        }
        return "\(input.count) parameters"
    }

    var inputJSON: String {
        if let data = try? JSONSerialization.data(withJSONObject: input, options: .prettyPrinted),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "{}"
    }
}

struct ToolResult: Identifiable {
    let id: String
    let toolUseId: String
    let content: String
    let isError: Bool

    var contentPreview: String {
        let lines = content.components(separatedBy: .newlines)
        if lines.count > 5 {
            return lines.prefix(5).joined(separator: "\n") + "\n..."
        }
        return content
    }
}
