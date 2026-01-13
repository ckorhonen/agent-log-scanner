import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            SessionListView()
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            if appState.isLoadingSession {
                ProgressView("Loading session...")
            } else if let session = appState.selectedSession {
                SessionDetailView(session: session)
            } else {
                ContentUnavailableView(
                    "No Session Selected",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Select a session from the sidebar to view its contents")
                )
            }
        }
        .navigationTitle("Agent Log Scanner")
        .task {
            await appState.sessionStore.loadSessions()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
