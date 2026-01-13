import SwiftUI

struct SessionListView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 0) {
            // Filter dropdown
            SessionFilterView()
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider()

            // Session list
            if appState.sessionStore.isLoading && appState.sessionStore.sessions.isEmpty {
                Spacer()
                ProgressView("Loading sessions...")
                Spacer()
            } else if appState.sessionStore.sessions.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Sessions Found",
                    systemImage: "tray",
                    description: Text("No Claude Code sessions found in ~/.claude/projects/")
                )
                Spacer()
            } else {
                List(selection: $appState.selectedSessionID) {
                    ForEach(filteredSessions) { session in
                        SessionRowView(session: session)
                            .tag(session.id)
                    }

                    if appState.sessionStore.hasMoreSessions {
                        Button("Load More...") {
                            Task {
                                await appState.sessionStore.loadMoreSessions()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.sidebar)
                .onChange(of: appState.selectedSessionID) { _, newValue in
                    Task {
                        await appState.selectSession(newValue)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await appState.sessionStore.loadSessions()
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh session list")
            }
        }
    }

    private var filteredSessions: [SessionSummary] {
        appState.sessionStore.filteredSessions(by: appState.projectFilter)
    }
}

struct SessionFilterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        Picker("Project", selection: $appState.projectFilter) {
            Text("All Projects")
                .tag(nil as String?)

            Divider()

            ForEach(appState.sessionStore.projects, id: \.self) { project in
                Text(project)
                    .tag(project as String?)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
    }
}

struct SessionRowView: View {
    let session: SessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.projectName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text("\(session.turnCount) turns")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }

            Text(session.displayTimestamp)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SessionListView()
        .environment(AppState())
        .frame(width: 300)
}
