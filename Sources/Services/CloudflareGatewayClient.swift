import Foundation
import Security

struct CloudflareGatewayMessage: Encodable, Equatable {
    let role: String
    let content: String
}

struct CloudflareGatewayMetadata: Equatable {
    private static let keys = ["app", "env", "surface", "feature", "caller"]

    let app: String
    let env: String
    let surface: String
    let feature: String
    let caller: String

    var dictionary: [String: String] {
        [
            "app": app,
            "env": env,
            "surface": surface,
            "feature": feature,
            "caller": caller
        ]
    }

    init(values: [String: String]) throws {
        for key in Self.keys {
            guard let value = values[key], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CloudflareGatewayError.invalidMetadata("Gateway metadata is missing required key: \(key)")
            }
        }

        app = values["app"]!
        env = values["env"]!
        surface = values["surface"]!
        feature = values["feature"]!
        caller = values["caller"]!
    }

    static func fromEnvironment(
        _ environment: [String: String] = ProcessInfo.processInfo.environment,
        feature defaultFeature: String
    ) throws -> CloudflareGatewayMetadata {
        var values = [
            "app": "agent-log-scanner",
            "env": "local",
            "surface": "desktop",
            "feature": defaultFeature,
            "caller": "ckorhonen"
        ]

        if let rawMetadata = environment["CF_AIG_METADATA"], !rawMetadata.isEmpty {
            guard let data = rawMetadata.data(using: .utf8),
                  let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw CloudflareGatewayError.invalidMetadata("CF_AIG_METADATA must be a JSON object")
            }

            for key in keys {
                if let value = object[key] {
                    values[key] = try stringifyMetadataValue(value, key: key)
                }
            }
        }

        for key in keys {
            let envName = "CF_AIG_\(key.uppercased())"
            if let value = environment[envName], !value.isEmpty {
                values[key] = value
            }
        }

        return try CloudflareGatewayMetadata(values: values)
    }

    private static func stringifyMetadataValue(_ value: Any, key: String) throws -> String {
        if let string = value as? String {
            return string
        }

        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        }

        throw CloudflareGatewayError.invalidMetadata("Gateway metadata value for \(key) must be a string, number, or boolean")
    }
}

struct CloudflareGatewayClient {
    typealias RequestPerformer = (URLRequest) async throws -> (Data, HTTPURLResponse)

    private static let baseURL = URL(string: "https://gateway.ai.cloudflare.com/v1/ea76e5b24c115e61c4ca83acb28b7e4d/sourcebottle/compat")!
    private static let keychainService = "cloudflare-ai-gateway-sourcebottle-token"

    private let tokenProvider: () throws -> String?
    private let performRequest: RequestPerformer

    init(
        tokenProvider: @escaping () throws -> String? = CloudflareGatewayClient.defaultTokenProvider,
        performRequest: @escaping RequestPerformer = CloudflareGatewayClient.urlSessionRequest
    ) {
        self.tokenProvider = tokenProvider
        self.performRequest = performRequest
    }

    func chatCompletion(
        model: String,
        messages: [CloudflareGatewayMessage],
        metadata: CloudflareGatewayMetadata,
        collectLogPayload: Bool = true
    ) async throws -> String {
        guard let token = try tokenProvider(), !token.isEmpty else {
            throw CloudflareGatewayError.missingToken
        }

        let url = Self.baseURL.appendingPathComponent("chat").appendingPathComponent("completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(token.hasPrefix("Bearer ") ? token : "Bearer \(token)", forHTTPHeaderField: "cf-aig-authorization")
        request.setValue(String(collectLogPayload), forHTTPHeaderField: "cf-aig-collect-log-payload")
        request.setValue(try metadataHeaderValue(metadata), forHTTPHeaderField: "cf-aig-metadata")
        request.httpBody = try JSONEncoder().encode(ChatCompletionRequest(model: model, messages: messages))

        let (data, response) = try await performRequest(request)
        guard (200..<300).contains(response.statusCode) else {
            throw CloudflareGatewayError.requestFailed(response.statusCode, Self.responseMessage(from: data))
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw CloudflareGatewayError.invalidResponse
        }

        return content
    }

    static func configuredModel(specificEnvName: String, defaultModel: String) -> String {
        let environment = ProcessInfo.processInfo.environment
        return environment[specificEnvName]
            ?? environment["CF_AIG_AGENT_LOG_SCANNER_MODEL"]
            ?? defaultModel
    }

    private static func defaultTokenProvider() throws -> String? {
        if let token = ProcessInfo.processInfo.environment["CLOUDFLARE_AI_GATEWAY_TOKEN"], !token.isEmpty {
            return token
        }

        return readKeychainToken()
    }

    private static func readKeychainToken() -> String? {
        if let token = readKeychainToken(account: NSUserName()) {
            return token
        }
        return readKeychainToken(account: nil)
    }

    private static func readKeychainToken(account: String?) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        if let account {
            query[kSecAttrAccount as String] = account
        }

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private static func urlSessionRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudflareGatewayError.invalidResponse
        }
        return (data, httpResponse)
    }

    private func metadataHeaderValue(_ metadata: CloudflareGatewayMetadata) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: metadata.dictionary, options: [.sortedKeys])
        guard let value = String(data: data, encoding: .utf8) else {
            throw CloudflareGatewayError.invalidMetadata("Gateway metadata could not be encoded")
        }
        return value
    }

    private static func responseMessage(from data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = object["error"] {
            if let errorObject = error as? [String: Any],
               let message = errorObject["message"] as? String {
                return message
            }
            return String(describing: error)
        }

        return String(data: data, encoding: .utf8) ?? "AI Gateway request failed"
    }
}

enum CloudflareGatewayError: LocalizedError, Equatable {
    case missingToken
    case invalidMetadata(String)
    case invalidResponse
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Cloudflare AI Gateway token not found. Set CLOUDFLARE_AI_GATEWAY_TOKEN or add the cloudflare-ai-gateway-sourcebottle-token Keychain item."
        case .invalidMetadata(let message):
            return message
        case .invalidResponse:
            return "Invalid response from Cloudflare AI Gateway"
        case .requestFailed(let statusCode, let message):
            return "Cloudflare AI Gateway error (\(statusCode)): \(message)"
        }
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [CloudflareGatewayMessage]
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]
}
