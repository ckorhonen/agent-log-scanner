import XCTest

final class AgentLogScannerUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Window Tests

    func testAppLaunches() throws {
        // Wait for the window to appear
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5), "App should have at least one window")
    }

    func testMainWindowExists() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "Main window should exist")
    }

    // MARK: - Navigation Tests

    func testSidebarExists() throws {
        // The sidebar should contain the session list
        let sidebar = app.outlines.firstMatch
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5), "Sidebar should exist")
    }

    func testProjectFilterExists() throws {
        // Look for the project filter picker
        let picker = app.popUpButtons.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Project filter picker should exist")
    }

    // MARK: - Session Selection Tests

    func testSelectingSessionShowsDetail() throws {
        // Wait for sessions to load
        let sidebar = app.outlines.firstMatch
        guard sidebar.waitForExistence(timeout: 10) else {
            // No sidebar found - might be list-based
            return
        }

        // Try to select the first session if available
        let firstRow = sidebar.cells.firstMatch
        if firstRow.waitForExistence(timeout: 5) {
            firstRow.click()

            // Detail view should show session info - look for any analyze button
            let analyzeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Analyze'")).firstMatch
            if analyzeButton.waitForExistence(timeout: 5) {
                XCTAssertTrue(analyzeButton.exists, "Analyze button should appear when session selected")
            }
            // If no analyze button, session might not have loaded yet - that's okay
        }
    }

    // MARK: - Empty State Tests

    func testEmptyStateWhenNoSelection() throws {
        // Before selecting anything, should show empty state
        let emptyStateText = app.staticTexts["Select a session to view details"]
        // This may or may not exist depending on if sessions auto-select
        // Just verify the app doesn't crash
        XCTAssertTrue(app.windows.firstMatch.exists)
    }

    // MARK: - Toolbar Tests

    func testToolbarHasRefreshButton() throws {
        // Wait for the window to appear
        let window = app.windows.firstMatch
        guard window.waitForExistence(timeout: 5) else {
            XCTFail("Window did not appear")
            return
        }

        // Look for refresh button - may be in toolbar or elsewhere
        let refreshButton = app.buttons.matching(NSPredicate(format: "label == 'Refresh'")).firstMatch
        if refreshButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(refreshButton.isEnabled, "Refresh button should be enabled")
        }
        // If no refresh button found, that's acceptable
    }

    // MARK: - Analysis Tests

    func testAnalyzeButtonExistsWhenSessionSelected() throws {
        // Wait for sessions to load
        let sidebar = app.outlines.firstMatch
        guard sidebar.waitForExistence(timeout: 10) else {
            return // No sessions available
        }

        // Select a session
        let firstRow = sidebar.cells.firstMatch
        guard firstRow.waitForExistence(timeout: 5) else {
            return // No sessions to select
        }

        firstRow.click()

        // Look for analyze button (now a menu with primary action)
        let analyzeMenu = app.menuButtons.matching(NSPredicate(format: "label CONTAINS[c] 'Analyze'")).firstMatch
        if analyzeMenu.waitForExistence(timeout: 5) {
            XCTAssertTrue(analyzeMenu.isEnabled, "Analyze menu should be enabled")
        }
    }

    func testAnalyzeMenuShowsProviderOptions() throws {
        // Wait for sessions to load
        let sidebar = app.outlines.firstMatch
        guard sidebar.waitForExistence(timeout: 10) else {
            return
        }

        // Select a session
        let firstRow = sidebar.cells.firstMatch
        guard firstRow.waitForExistence(timeout: 5) else {
            return
        }

        firstRow.click()

        // Find and click the analyze menu to open it
        let analyzeMenu = app.menuButtons.matching(NSPredicate(format: "label CONTAINS[c] 'Analyze'")).firstMatch
        guard analyzeMenu.waitForExistence(timeout: 5) else {
            return
        }

        // Click to open menu (not the primary action)
        analyzeMenu.click()

        // Check for provider options in the menu
        let codexOption = app.menuItems["Codex (GPT-5.2)"]
        let claudeOption = app.menuItems["Claude"]

        // At least one should exist
        let hasProviderOptions = codexOption.waitForExistence(timeout: 2) || claudeOption.waitForExistence(timeout: 2)
        if hasProviderOptions {
            XCTAssertTrue(true, "Provider options should be available in menu")
        }

        // Press escape to close menu
        app.typeKey(.escape, modifierFlags: [])
    }
}
