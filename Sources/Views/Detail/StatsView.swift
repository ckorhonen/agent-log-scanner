import SwiftUI

struct StatsView: View {
    let stats: SessionStats

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Statistics")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    StatLabel(icon: "person.fill", label: "Human Messages")
                    Text("\(stats.humanMessageCount)")
                        .font(.body.monospacedDigit())
                }

                GridRow {
                    StatLabel(icon: "sparkles", label: "Assistant Messages")
                    Text("\(stats.assistantMessageCount)")
                        .font(.body.monospacedDigit())
                }

                GridRow {
                    StatLabel(icon: "arrow.left.arrow.right", label: "Turns")
                    Text("\(stats.turnCount)")
                        .font(.body.monospacedDigit())
                }

                GridRow {
                    StatLabel(icon: "wrench.fill", label: "Tool Calls")
                    Text("\(stats.toolCallCount)")
                        .font(.body.monospacedDigit())
                }

                if stats.errorCount > 0 {
                    GridRow {
                        StatLabel(icon: "exclamationmark.triangle.fill", label: "Errors", color: .red)
                        Text("\(stats.errorCount)")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.red)
                    }
                }

                if let duration = stats.formattedDuration {
                    GridRow {
                        StatLabel(icon: "clock.fill", label: "Duration")
                        Text(duration)
                            .font(.body.monospacedDigit())
                    }
                }
            }

            if !stats.toolCallsByName.isEmpty {
                Divider()

                Text("Tools Used")
                    .font(.subheadline.bold())

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(stats.toolCallsByName.sorted(by: { $0.value > $1.value }), id: \.key) { tool, count in
                        HStack {
                            Text(tool)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text("\(count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatLabel: View {
    let icon: String
    let label: String
    var color: Color = .primary

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 16)

            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    StatsView(stats: SessionStats(messages: []))
        .frame(width: 350)
}
