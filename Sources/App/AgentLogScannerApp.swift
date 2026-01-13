import SwiftUI

@main
struct AgentLogScannerApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandMenu("Session") {
                Button("Refresh Sessions") {
                    Task {
                        await appState.sessionStore.loadSessions()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("Analyze Session") {
                    if appState.selectedSession != nil {
                        Task {
                            await appState.analyzeCurrentSession()
                        }
                    }
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .disabled(appState.selectedSession == nil)
            }
        }

        Settings {
            SettingsView()
        }
    }
}
