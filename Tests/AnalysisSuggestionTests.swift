import XCTest
@testable import Agent_Log_Scanner

final class AnalysisSuggestionTests: XCTestCase {

    func testDecodeSuggestionFromJSON() throws {
        let json = """
        {
            "category": "preference",
            "target": "global",
            "suggestion": "Prefer brevity in responses",
            "reasoning": "User asked for shorter responses multiple times",
            "evidence": "User: Please be more concise"
        }
        """

        let data = json.data(using: .utf8)!
        let suggestion = try JSONDecoder().decode(AnalysisSuggestion.self, from: data)

        XCTAssertEqual(suggestion.category, .preference)
        XCTAssertEqual(suggestion.target, .global)
        XCTAssertEqual(suggestion.suggestion, "Prefer brevity in responses")
        XCTAssertEqual(suggestion.reasoning, "User asked for shorter responses multiple times")
        XCTAssertEqual(suggestion.evidence, "User: Please be more concise")
    }

    func testDecodeSuggestionArray() throws {
        let json = """
        [
            {
                "category": "workflow",
                "target": "project",
                "suggestion": "Always run tests after changes",
                "reasoning": "Tests caught bugs that would have been missed",
                "evidence": "Test failures revealed issue in line 42"
            },
            {
                "category": "tool-usage",
                "target": "global",
                "suggestion": "Use Grep for searching instead of cat | grep",
                "reasoning": "More efficient tool usage",
                "evidence": "Multiple instances of cat file | grep pattern"
            }
        ]
        """

        let data = json.data(using: .utf8)!
        let suggestions = try JSONDecoder().decode([AnalysisSuggestion].self, from: data)

        XCTAssertEqual(suggestions.count, 2)
        XCTAssertEqual(suggestions[0].category, .workflow)
        XCTAssertEqual(suggestions[1].category, .toolUsage)
    }

    func testAllCategories() throws {
        let categories: [(String, AnalysisSuggestion.Category)] = [
            ("preference", .preference),
            ("workflow", .workflow),
            ("tool-usage", .toolUsage),
            ("error-prevention", .errorPrevention),
            ("knowledge", .knowledge),
            ("skill", .skill)
        ]

        for (rawValue, expected) in categories {
            let json = """
            {
                "category": "\(rawValue)",
                "target": "global",
                "suggestion": "Test",
                "reasoning": "Test",
                "evidence": "Test"
            }
            """

            let data = json.data(using: .utf8)!
            let suggestion = try JSONDecoder().decode(AnalysisSuggestion.self, from: data)
            XCTAssertEqual(suggestion.category, expected, "Failed for category: \(rawValue)")
        }
    }

    func testTargetTypes() throws {
        let targets: [(String, AnalysisSuggestion.Target)] = [
            ("global", .global),
            ("project", .project)
        ]

        for (rawValue, expected) in targets {
            let json = """
            {
                "category": "preference",
                "target": "\(rawValue)",
                "suggestion": "Test",
                "reasoning": "Test",
                "evidence": "Test"
            }
            """

            let data = json.data(using: .utf8)!
            let suggestion = try JSONDecoder().decode(AnalysisSuggestion.self, from: data)
            XCTAssertEqual(suggestion.target, expected, "Failed for target: \(rawValue)")
        }
    }

    func testCategoryDisplayNames() {
        XCTAssertEqual(AnalysisSuggestion.Category.preference.displayName, "Preference")
        XCTAssertEqual(AnalysisSuggestion.Category.workflow.displayName, "Workflow")
        XCTAssertEqual(AnalysisSuggestion.Category.toolUsage.displayName, "Tool Usage")
        XCTAssertEqual(AnalysisSuggestion.Category.errorPrevention.displayName, "Error Prevention")
        XCTAssertEqual(AnalysisSuggestion.Category.knowledge.displayName, "Knowledge")
        XCTAssertEqual(AnalysisSuggestion.Category.skill.displayName, "Skill")
    }

    func testCategoryIcons() {
        XCTAssertEqual(AnalysisSuggestion.Category.preference.icon, "person.fill")
        XCTAssertEqual(AnalysisSuggestion.Category.workflow.icon, "arrow.triangle.branch")
        XCTAssertEqual(AnalysisSuggestion.Category.toolUsage.icon, "wrench.fill")
        XCTAssertEqual(AnalysisSuggestion.Category.errorPrevention.icon, "exclamationmark.shield.fill")
        XCTAssertEqual(AnalysisSuggestion.Category.knowledge.icon, "book.fill")
        XCTAssertEqual(AnalysisSuggestion.Category.skill.icon, "wand.and.stars")
    }

    func testTargetDisplayNames() {
        XCTAssertEqual(AnalysisSuggestion.Target.global.displayName, "Global CLAUDE.md")
        XCTAssertEqual(AnalysisSuggestion.Target.project.displayName, "Project CLAUDE.md")
    }
}
