import Foundation

enum AnalysisProvider: String, CaseIterable, Identifiable {
    case codex = "codex"
    case claude = "claude"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codex: return "Codex (GPT-5.2)"
        case .claude: return "Claude"
        }
    }

    var icon: String {
        switch self {
        case .codex: return "brain.head.profile"
        case .claude: return "sparkles"
        }
    }
}
