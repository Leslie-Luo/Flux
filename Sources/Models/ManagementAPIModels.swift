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

// MARK: - API Keys Response

struct APIKeysResponse: Decodable {
    let keys: [String]?

    var count: Int { keys?.count ?? 0 }

    private enum CodingKeys: String, CodingKey {
        case apiKeys = "api-keys"
        case apiKeysAlt = "apiKeys"
    }

    // 兼容多种返回格式
    init(from decoder: Decoder) throws {
        // 尝试 { "api-keys": [...] } 或 { "apiKeys": [...] }
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            if let keys = try? container.decodeIfPresent([String].self, forKey: .apiKeys) {
                self.keys = keys
                return
            }
            if let keys = try? container.decodeIfPresent([String].self, forKey: .apiKeysAlt) {
                self.keys = keys
                return
            }
        }
        // 尝试直接数组
        if let array = try? decoder.singleValueContainer().decode([String].self) {
            self.keys = array
            return
        }
        self.keys = nil
    }
}

// MARK: - Provider API Keys

/// 通用的 Provider Key 条目，用于 gemini/codex/claude-api-key
struct ProviderKeyEntry: Decodable, Equatable {
    let apiKey: String?
    let baseUrl: String?
    let proxyUrl: String?
    let prefix: String?
    let headers: [String: String]?
    let excludedModels: [String]?
    let models: [ModelMapping]?

    enum CodingKeys: String, CodingKey {
        case apiKey = "api-key"
        case baseUrl = "base-url"
        case proxyUrl = "proxy-url"
        case prefix
        case headers
        case excludedModels = "excluded-models"
        case models
    }
}

struct GeminiApiKeyResponse: Decodable {
    let keys: [ProviderKeyEntry]?

    var count: Int { keys?.count ?? 0 }

    private enum CodingKeys: String, CodingKey {
        case keys = "gemini-api-key"
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.keys = try container.decodeIfPresent([ProviderKeyEntry].self, forKey: .keys)
            return
        }
        if let array = try? decoder.singleValueContainer().decode([ProviderKeyEntry].self) {
            self.keys = array
            return
        }
        self.keys = nil
    }
}

struct CodexApiKeyResponse: Decodable {
    let keys: [ProviderKeyEntry]?

    var count: Int { keys?.count ?? 0 }

    private enum CodingKeys: String, CodingKey {
        case keys = "codex-api-key"
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.keys = try container.decodeIfPresent([ProviderKeyEntry].self, forKey: .keys)
            return
        }
        if let array = try? decoder.singleValueContainer().decode([ProviderKeyEntry].self) {
            self.keys = array
            return
        }
        self.keys = nil
    }
}

struct ClaudeApiKeyResponse: Decodable {
    let keys: [ProviderKeyEntry]?

    var count: Int { keys?.count ?? 0 }

    private enum CodingKeys: String, CodingKey {
        case keys = "claude-api-key"
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.keys = try container.decodeIfPresent([ProviderKeyEntry].self, forKey: .keys)
            return
        }
        if let array = try? decoder.singleValueContainer().decode([ProviderKeyEntry].self) {
            self.keys = array
            return
        }
        self.keys = nil
    }
}

/// OpenAI 兼容提供商条目
struct OpenAICompatibilityEntry: Decodable, Equatable {
    let name: String?
    let baseUrl: String?
    let apiKeyEntries: [OpenAICompatApiKeyEntry]?
    let models: [ModelMapping]?
    let headers: [String: String]?

    enum CodingKeys: String, CodingKey {
        case name
        case baseUrl = "base-url"
        case apiKeyEntries = "api-key-entries"
        case models
        case headers
    }

    static func == (lhs: OpenAICompatibilityEntry, rhs: OpenAICompatibilityEntry) -> Bool {
        lhs.name == rhs.name &&
        lhs.baseUrl == rhs.baseUrl
    }
}

/// OpenAI 兼容提供商的 API Key 条目
struct OpenAICompatApiKeyEntry: Codable, Equatable {
    let apiKey: String?
    let proxyUrl: String?

    enum CodingKeys: String, CodingKey {
        case apiKey = "api-key"
        case proxyUrl = "proxy-url"
    }
}

/// 模型映射（用于 alias）
struct ModelMapping: Codable, Equatable {
    let name: String?
    let alias: String?
}

struct OpenAICompatibilityResponse: Decodable {
    let entries: [OpenAICompatibilityEntry]?

    var count: Int { entries?.count ?? 0 }

    private enum CodingKeys: String, CodingKey {
        case entries = "openai-compatibility"
    }

    // 兼容多种返回格式
    init(from decoder: Decoder) throws {
        // 尝试解码 { "openai-compatibility": [...] }
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.entries = try container.decodeIfPresent([OpenAICompatibilityEntry].self, forKey: .entries)
            return
        }
        // 尝试直接解码数组
        if let array = try? decoder.singleValueContainer().decode([OpenAICompatibilityEntry].self) {
            self.entries = array
            return
        }
        self.entries = nil
    }
}

// MARK: - Auth Files

/// 认证文件信息（来自 /auth-files 端点）
struct AuthFile: Decodable, Equatable {
    let id: String?
    let name: String?
    let type: String?  // 降级模式下返回
    let provider: String?
    let label: String?
    let status: String?
    let statusMessage: String?
    let disabled: Bool?
    let unavailable: Bool?
    let runtimeOnly: Bool?
    let source: String?
    let path: String?
    let size: Int?
    let modtime: String?
    let email: String?
    let accountType: String?
    let account: String?
    let createdAt: String?
    let updatedAt: String?
    let lastRefresh: String?

    enum CodingKeys: String, CodingKey {
        case id, name, type, provider, label, status, disabled, unavailable, source, path, size, modtime, email, account
        case statusMessage = "status_message"
        case runtimeOnly = "runtime_only"
        case accountType = "account_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastRefresh = "last_refresh"
    }

    static func == (lhs: AuthFile, rhs: AuthFile) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name
    }
}

struct AuthFilesResponse: Decodable {
    let files: [AuthFile]?

    var count: Int { files?.count ?? 0 }
}

// MARK: - Models

struct ModelInfo: Codable, Identifiable {
    let id: String
    let displayName: String?
    let ownedBy: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case ownedBy = "owned_by"
    }
}

struct ModelsResponse: Codable {
    let data: [ModelInfo]?
    let models: [ModelInfo]?

    var allModels: [ModelInfo] { data ?? models ?? [] }
    var count: Int { allModels.count }
}

// MARK: - Dashboard Stats

struct DashboardStats: Equatable {
    var apiKeysCount: Int = 0
    var providersCount: Int = 0
    var authFilesCount: Int = 0
    var modelsCount: Int = 0

    // Provider breakdown
    var geminiCount: Int = 0
    var codexCount: Int = 0
    var claudeCount: Int = 0
    var openaiCompatCount: Int = 0
}

// MARK: - Status Response

struct StatusOKResponse: Codable, Equatable {
    let status: String
}

// MARK: - Provider Key Payload (Request)

struct ProviderKeyPayload: Codable {
    let apiKey: String?
    let baseUrl: String?
    let proxyUrl: String?
    let prefix: String?
    let headers: [String: String]?
    let excludedModels: [String]?
    let models: [ModelMapping]?

    enum CodingKeys: String, CodingKey {
        case apiKey = "api-key"
        case baseUrl = "base-url"
        case proxyUrl = "proxy-url"
        case prefix
        case headers
        case excludedModels = "excluded-models"
        case models
    }
}

// MARK: - OpenAI Compatibility Payload (Request)

struct OpenAICompatPayload: Codable {
    let name: String
    let baseUrl: String?
    let apiKeyEntries: [OpenAICompatApiKeyEntry]?
    let models: [ModelMapping]?
    let headers: [String: String]?

    enum CodingKeys: String, CodingKey {
        case name
        case baseUrl = "base-url"
        case apiKeyEntries = "api-key-entries"
        case models
        case headers
    }
}

// MARK: - Patch Wrappers

struct IndexValuePatch<T: Codable>: Codable {
    let index: Int
    let value: T
}

struct MatchValuePatch<T: Codable>: Codable {
    let match: String
    let value: T
}

struct NameValuePatch<T: Codable>: Codable {
    let name: String
    let value: T
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
