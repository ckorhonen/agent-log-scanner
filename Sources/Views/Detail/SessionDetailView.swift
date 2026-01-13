import SwiftUI

struct SessionDetailView: View {
    @Environment(AppState.self) private var appState
    let session: Session

    @State private var showingAnalysis = false

    var body: some View {
        HSplitView {
            // Main conversation view
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(session.messages) { message in
                        MessageView(message: message)
                    }
                }
                .padding()
            }
            .frame(minWidth: 400)

            // Right panel: Stats + Analysis
            VStack(spacing: 0) {
                StatsView(stats: session.stats)

                Divider()

                AnalysisView()
            }
            .frame(width: 350)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await appState.analyzeCurrentSession()
                    }
                }) {
                    if appState.isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Label("Analyze", systemImage: "sparkles")
                    }
                }
                .disabled(appState.isAnalyzing)
                .help("Analyze session with Claude")
            }
        }
        .navigationSubtitle("\(session.projectName) · \(session.stats.turnCount) turns")
    }
}

struct MessageView: View {
    let message: Message

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Role header
            HStack {
                Image(systemName: message.role == .user ? "person.fill" : "sparkles")
                    .foregroundStyle(message.role == .user ? .blue : .purple)

                Text(message.role == .user ? "Human" : "Assistant")
                    .font(.headline)
                    .foregroundStyle(message.role == .user ? .blue : .purple)

                Spacer()

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Content blocks
            ForEach(message.content) { block in
                ContentBlockView(block: block)
            }
        }
        .padding()
        .background(message.role == .user ? Color.blue.opacity(0.05) : Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ContentBlockView: View {
    let block: ContentBlock

    var body: some View {
        switch block {
        case .text(let text):
            TextBlockView(text: text)
        case .toolUse(let tool):
            ToolCallView(tool: tool)
        case .toolResult(let result):
            ToolResultView(result: result)
        }
    }
}

struct TextBlockView: View {
    let text: String

    var body: some View {
        Text(text)
            .textSelection(.enabled)
            .font(.body)
    }
}

struct ToolCallView: View {
    let tool: ToolCall

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(tool.inputJSON)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        } label: {
            HStack {
                Image(systemName: "wrench.fill")
                    .foregroundStyle(.orange)

                Text(tool.name)
                    .font(.subheadline.bold())

                Text(tool.inputSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct ToolResultView: View {
    let result: ToolResult

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ScrollView {
                Text(result.content)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            .padding(8)
            .background(Color.black.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        } label: {
            HStack {
                Image(systemName: result.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(result.isError ? .red : .green)

                Text("Result")
                    .font(.subheadline)

                if result.isError {
                    Text("Error")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(8)
        .background(result.isError ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
