import Foundation

struct AnalysisSuggestion: Identifiable, Codable {
    let id: UUID
    let category: Category
    let target: Target
    let suggestion: String
    let reasoning: String
    let evidence: String

    enum Category: String, Codable, CaseIterable {
        case preference
        case workflow
        case toolUsage = "tool-usage"
        case errorPrevention = "error-prevention"
        case knowledge

        var displayName: String {
            switch self {
            case .preference: return "Preference"
            case .workflow: return "Workflow"
            case .toolUsage: return "Tool Usage"
            case .errorPrevention: return "Error Prevention"
            case .knowledge: return "Knowledge"
            }
        }

        var color: String {
            switch self {
            case .preference: return "blue"
            case .workflow: return "green"
            case .toolUsage: return "orange"
            case .errorPrevention: return "red"
            case .knowledge: return "purple"
            }
        }
    }

    enum Target: String, Codable {
        case project
        case global

        var displayName: String {
            switch self {
            case .project: return "Project CLAUDE.md"
            case .global: return "Global CLAUDE.md"
            }
        }
    }

    init(id: UUID = UUID(), category: Category, target: Target, suggestion: String, reasoning: String, evidence: String) {
        self.id = id
        self.category = category
        self.target = target
        self.suggestion = suggestion
        self.reasoning = reasoning
        self.evidence = evidence
    }

    // Custom decoding to handle the JSON from Claude
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Generate a new UUID since it's not in the JSON
        self.id = UUID()

        // Decode category with fallback
        let categoryString = try container.decode(String.self, forKey: .category)
        self.category = Category(rawValue: categoryString) ?? .knowledge

        // Decode target with fallback
        let targetString = try container.decode(String.self, forKey: .target)
        self.target = Target(rawValue: targetString) ?? .project

        self.suggestion = try container.decode(String.self, forKey: .suggestion)
        self.reasoning = try container.decode(String.self, forKey: .reasoning)
        self.evidence = try container.decode(String.self, forKey: .evidence)
    }

    private enum CodingKeys: String, CodingKey {
        case category, target, suggestion, reasoning, evidence
    }
}
