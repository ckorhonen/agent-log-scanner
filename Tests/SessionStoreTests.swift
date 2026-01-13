import XCTest
@testable import Agent_Log_Scanner

final class SessionStoreTests: XCTestCase {

    func testExtractProjectName() {
        let path = "-Users-ckorhonen-Vault-Vault"
        let name = Session.extractProjectName(from: path)
        XCTAssertEqual(name, "Vault")
    }

    func testExtractProjectNameComplex() {
        // Path uses dashes as separators, so "agent-log-scanner" becomes "agent/log/scanner"
        // and last component is "scanner"
        let path = "-Users-ckorhonen-Repos-ckorhonen-agent-log-scanner"
        let name = Session.extractProjectName(from: path)
        XCTAssertEqual(name, "scanner")
    }
}
