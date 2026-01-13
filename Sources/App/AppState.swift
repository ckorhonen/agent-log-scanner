import SwiftUI

@Observable
class AppState {
    let sessionStore = SessionStore()
    let claudeAnalyzer = ClaudeAnalyzer()
    let claudeMDManager = ClaudeMDManager()

    var selectedSessionID: UUID?
    var selectedSession: Session?
    var isLoadingSession = false

    var analysisSuggestions: [AnalysisSuggestion] = []
    var isAnalyzing = false
    var analysisError: String?

    var projectFilter: String? = nil // nil means "All Projects"

    func selectSession(_ id: UUID?) async {
        selectedSessionID = id
        selectedSession = nil
        analysisSuggestions = []
        analysisError = nil

        guard let id = id else { return }

        isLoadingSession = true
        defer { isLoadingSession = false }

        if let summary = sessionStore.sessions.first(where: { $0.id == id }) {
            do {
                selectedSession = try await sessionStore.loadFullSession(summary)
            } catch {
                print("Error loading session: \(error)")
            }
        }
    }

    func analyzeCurrentSession() async {
        guard let session = selectedSession else { return }

        isAnalyzing = true
        analysisError = nil
        analysisSuggestions = []

        defer { isAnalyzing = false }

        do {
            let globalCLAUDEMD = claudeMDManager.readGlobalCLAUDEMD()
            let projectCLAUDEMD = claudeMDManager.readProjectCLAUDEMD(projectPath: session.projectPath)

            analysisSuggestions = try await claudeAnalyzer.analyze(
                session: session,
                globalCLAUDEMD: globalCLAUDEMD,
                projectCLAUDEMD: projectCLAUDEMD
            )
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
