import XCTest
@testable import AgentLogScanner

final class SessionStoreTests: XCTestCase {

    func testExtractProjectName() {
        let path = "-Users-ckorhonen-Vault-Vault"
        let name = Session.extractProjectName(from: path)
        XCTAssertEqual(name, "Vault")
    }

    func testExtractProjectNameComplex() {
        let path = "-Users-ckorhonen-Repos-ckorhonen-agent-log-scanner"
        let name = Session.extractProjectName(from: path)
        XCTAssertEqual(name, "agent-log-scanner")
    }
}
