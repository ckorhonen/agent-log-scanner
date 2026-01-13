import SwiftUI

struct AnalysisView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Analysis")
                    .font(.headline)

                Spacer()

                if appState.isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding()

            Divider()

            if appState.isAnalyzing {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Analyzing session...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else if let error = appState.analysisError {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text("Analysis Failed")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else if appState.analysisSuggestions.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Analysis Yet")
                        .font(.headline)
                    Text("Click \"Analyze\" to get suggestions for improving your CLAUDE.md files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Show when analysis was done
                        if let date = appState.analysisDate {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.secondary)
                                Text("Analyzed \(date.formatted(.relative(presentation: .named)))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Re-analyze") {
                                    Task {
                                        await appState.analyzeCurrentSession()
                                    }
                                }
                                .font(.caption)
                                .buttonStyle(.link)
                            }
                            .padding(.horizontal)
                        }

                        ForEach(appState.analysisSuggestions) { suggestion in
                            SuggestionCardView(suggestion: suggestion)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct SuggestionCardView: View {
    @Environment(AppState.self) private var appState
    let suggestion: AnalysisSuggestion

    @State private var showingReasoning = false
    @State private var copied = false
    @State private var applied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with category and target
            HStack {
                CategoryBadge(category: suggestion.category)

                Spacer()

                Text(suggestion.target.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Suggestion text
            Text(suggestion.suggestion)
                .font(.body)
                .textSelection(.enabled)
                .lineLimit(nil)

            // Reasoning (expandable)
            DisclosureGroup("Why?", isExpanded: $showingReasoning) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(suggestion.reasoning)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !suggestion.evidence.isEmpty {
                        Divider()
                        Text("Evidence:")
                            .font(.caption.bold())
                        Text(suggestion.evidence)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
            }
            .font(.caption)

            Divider()

            // Actions
            HStack {
                Button(action: copyToClipboard) {
                    Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(action: applySuggestion) {
                    Label(applied ? "Applied!" : "Apply", systemImage: applied ? "checkmark.circle.fill" : "plus.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(applied)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(suggestion.suggestion, forType: .string)
        copied = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }

    private func applySuggestion() {
        appState.applySuggestion(suggestion)
        applied = true
    }
}

struct CategoryBadge: View {
    let category: AnalysisSuggestion.Category

    var body: some View {
        Text(category.displayName)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(categoryColor.opacity(0.2))
            .foregroundStyle(categoryColor)
            .clipShape(Capsule())
    }

    private var categoryColor: Color {
        switch category {
        case .preference: return .blue
        case .workflow: return .green
        case .toolUsage: return .orange
        case .errorPrevention: return .red
        case .knowledge: return .purple
        }
    }
}

#Preview {
    AnalysisView()
        .environment(AppState())
        .frame(width: 350, height: 500)
}
