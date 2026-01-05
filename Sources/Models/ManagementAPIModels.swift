import Foundation

// MARK: - Config / Health

struct HealthResponse: Codable, Equatable {
    let status: String
    let version: String?
    let uptime: TimeInterval?

    // Config response fields (from /v0/management/config)
    let debug: Bool?
    let wsAuth: Bool?

    enum CodingKeys: String, CodingKey {
        case status, version, uptime, debug
        case wsAuth = "ws-auth"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // /config endpoint returns config object, not health status
        // If we can decode it, the connection is healthy
        self.debug = try container.decodeIfPresent(Bool.self, forKey: .debug)
        self.wsAuth = try container.decodeIfPresent(Bool.self, forKey: .wsAuth)
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
        self.uptime = try container.decodeIfPresent(TimeInterval.self, forKey: .uptime)
        // If decoding succeeds, status is OK
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "ok"
    }

    init(status: String, version: String? = nil, uptime: TimeInterval? = nil) {
        self.status = status
        self.version = version
        self.uptime = uptime
        self.debug = nil
        self.wsAuth = nil
    }
}

// MARK: - Accounts

struct AccountDTO: Codable, Identifiable, Equatable {
    let id: String
    let provider: String
    let name: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, provider, name
        case createdAt = "created_at"
    }
}

struct CreateAccountRequest: Codable {
    let provider: String
    let apiKey: String
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case provider
        case apiKey = "api_key"
        case name
    }
}

// MARK: - Strategies

struct StrategyDTO: Codable, Equatable {
    let current: String
    let available: [String]
}

struct UpdateStrategyRequest: Codable {
    let strategy: String
}

// MARK: - Error

enum ManagementAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int, body: String?)
    case decodingError(Error)
    case notConnected
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .httpError(let code, let body):
            return "HTTP 错误 \(code): \(body ?? "未知")"
        case .decodingError(let error):
            return "解码错误: \(error.localizedDescription)"
        case .notConnected:
            return "未连接到 CLIProxyAPI"
        case .unauthorized:
            return "认证失败，请检查密码"
        }
    }
}

