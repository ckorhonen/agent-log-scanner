import XCTest
@testable import Agent_Log_Scanner

final class CloudflareGatewayClientTests: XCTestCase {

    func testMetadataUsesJsonAndPerKeyEnvironmentOverrides() throws {
        let metadata = try CloudflareGatewayMetadata.fromEnvironment([
            "CF_AIG_METADATA": """
            {"app":"vault","env":"local","surface":"cli","feature":"chat","caller":"codex","ignored":"value"}
            """,
            "CF_AIG_APP": "agent-log-scanner",
            "CF_AIG_FEATURE": "session-analysis"
        ], feature: "fallback")

        XCTAssertEqual(metadata.dictionary, [
            "app": "agent-log-scanner",
            "env": "local",
            "surface": "cli",
            "feature": "session-analysis",
            "caller": "codex"
        ])
    }

    func testMetadataRejectsMalformedJson() {
        XCTAssertThrowsError(try CloudflareGatewayMetadata.fromEnvironment([
            "CF_AIG_METADATA": "not-json"
        ], feature: "session-analysis"))
    }

    func testChatCompletionSendsGatewayHeadersAndDecodesContent() async throws {
        var capturedRequest: URLRequest?
        let client = CloudflareGatewayClient(
            tokenProvider: { "cf-token" },
            performRequest: { request in
                capturedRequest = request
                let body = """
                {"choices":[{"message":{"content":"[]"}}]}
                """.data(using: .utf8)!
                return (body, HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            }
        )

        let content = try await client.chatCompletion(
            model: "openai/gpt-5-mini",
            messages: [CloudflareGatewayMessage(role: "user", content: "hello")],
            metadata: try CloudflareGatewayMetadata(values: [
                "app": "agent-log-scanner",
                "env": "local",
                "surface": "desktop",
                "feature": "session-analysis",
                "caller": "ckorhonen"
            ])
        )

        XCTAssertEqual(content, "[]")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "cf-aig-authorization"), "Bearer cf-token")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "authorization"), nil)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "cf-aig-collect-log-payload"), "true")

        let metadataHeader = try XCTUnwrap(capturedRequest?.value(forHTTPHeaderField: "cf-aig-metadata"))
        let metadataObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(metadataHeader.utf8)) as? [String: String]
        )
        XCTAssertEqual(metadataObject["app"], "agent-log-scanner")
        XCTAssertEqual(metadataObject["feature"], "session-analysis")
    }

    func testChatCompletionRequiresToken() async throws {
        let client = CloudflareGatewayClient(tokenProvider: { nil })

        do {
            _ = try await client.chatCompletion(
                model: "openai/gpt-5-mini",
                messages: [CloudflareGatewayMessage(role: "user", content: "hello")],
                metadata: try CloudflareGatewayMetadata(values: [
                    "app": "agent-log-scanner",
                    "env": "local",
                    "surface": "desktop",
                    "feature": "session-analysis",
                    "caller": "ckorhonen"
                ])
            )
            XCTFail("Expected missing token error")
        } catch let error as CloudflareGatewayError {
            XCTAssertEqual(error, .missingToken)
        }
    }
}
