import Foundation

/// Lightweight session metadata for sidebar list
struct SessionSummary: Identifiable, Hashable {
    let id: UUID
    let projectPath: String
    let projectName: String
    let timestamp: Date
    let turnCount: Int
    let filePath: URL

    var displayTimestamp: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: timestamp))"
        } else if calendar.isDateInYesterday(timestamp) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday, \(formatter.string(from: timestamp))"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: timestamp)
        }
    }
}
