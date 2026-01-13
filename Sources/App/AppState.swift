import SwiftUI

@Observable
class AppState {
    let sessionStore = SessionStore()
    let claudeAnalyzer = ClaudeAnalyzer()
    let codexAnalyzer = CodexAnalyzer()
    let claudeMDManager = ClaudeMDManager()
    let analysisStore = AnalysisStore()

    var selectedSessionID: String?
    var selectedSession: Session?
    var selectedSessionFilePath: URL?
    var isLoadingSession = false

    var analysisSuggestions: [AnalysisSuggestion] = []
    var analysisDate: Date?
    var isAnalyzing = false
    var analysisError: String?
    var analysisProvider: AnalysisProvider = .codex // Default to Codex

    var projectFilter: String? = nil // nil means "All Projects"

    func selectSession(_ id: String?) async {
        selectedSessionID = id
        selectedSession = nil
        selectedSessionFilePath = nil
        analysisSuggestions = []
        analysisDate = nil
        analysisError = nil

        guard let id = id else { return }

        isLoadingSession = true
        defer { isLoadingSession = false }

        if let summary = sessionStore.sessions.first(where: { $0.id == id }) {
            do {
                selectedSession = try await sessionStore.loadFullSession(summary)
                selectedSessionFilePath = summary.filePath

                // Load existing analysis if available
                if let wrapper = await analysisStore.load(for: summary.filePath) {
                    analysisSuggestions = wrapper.suggestions
                    analysisDate = wrapper.analyzedAt
                }
            } catch {
                print("Error loading session: \(error)")
            }
        }
    }

    func analyzeCurrentSession() async {
        guard let session = selectedSession,
              let filePath = selectedSessionFilePath else { return }

        isAnalyzing = true
        analysisError = nil
        analysisSuggestions = []
        analysisDate = nil

        defer { isAnalyzing = false }

        do {
            let globalCLAUDEMD = claudeMDManager.readGlobalCLAUDEMD()
            let projectCLAUDEMD = claudeMDManager.readProjectCLAUDEMD(projectPath: session.projectPath)

            let suggestions: [AnalysisSuggestion]
            switch analysisProvider {
            case .codex:
                suggestions = try await codexAnalyzer.analyze(
                    session: session,
                    globalCLAUDEMD: globalCLAUDEMD,
                    projectCLAUDEMD: projectCLAUDEMD
                )
            case .claude:
                suggestions = try await claudeAnalyzer.analyze(
                    session: session,
                    globalCLAUDEMD: globalCLAUDEMD,
                    projectCLAUDEMD: projectCLAUDEMD
                )
            }

            analysisSuggestions = suggestions
            analysisDate = Date()

            // Persist the analysis
            try await analysisStore.save(suggestions: suggestions, for: filePath)
        } catch {
            analysisError = error.localizedDescription
        }
    }

    func applySuggestion(_ suggestion: AnalysisSuggestion) {
        guard let session = selectedSession else { return }

        switch suggestion.target {
        case .global:
            claudeMDManager.appendToGlobalCLAUDEMD(suggestion.suggestion)
        case .project:
            claudeMDManager.appendToProjectCLAUDEMD(
                projectPath: session.projectPath,
                content: suggestion.suggestion
            )
        }
    }
}
