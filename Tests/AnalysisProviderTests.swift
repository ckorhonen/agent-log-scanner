import XCTest
@testable import Agent_Log_Scanner

final class AnalysisProviderTests: XCTestCase {

    func testDefaultProviderIsCodex() {
        let appState = AppState()
        XCTAssertEqual(appState.analysisProvider, .codex)
    }

    func testProviderDisplayNames() {
        XCTAssertEqual(AnalysisProvider.codex.displayName, "Codex (GPT-5.2)")
        XCTAssertEqual(AnalysisProvider.claude.displayName, "Claude")
    }

    func testProviderIcons() {
        XCTAssertEqual(AnalysisProvider.codex.icon, "brain.head.profile")
        XCTAssertEqual(AnalysisProvider.claude.icon, "sparkles")
    }

    func testProviderRawValues() {
        XCTAssertEqual(AnalysisProvider.codex.rawValue, "codex")
        XCTAssertEqual(AnalysisProvider.claude.rawValue, "claude")
    }

    func testAllCasesContainsBothProviders() {
        let allCases = AnalysisProvider.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.codex))
        XCTAssertTrue(allCases.contains(.claude))
    }

    func testProviderIdentifiable() {
        XCTAssertEqual(AnalysisProvider.codex.id, "codex")
        XCTAssertEqual(AnalysisProvider.claude.id, "claude")
    }
}
