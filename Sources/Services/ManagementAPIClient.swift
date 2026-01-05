import Foundation
import os.log

actor ManagementAPIClient {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.flux.app", category: "ManagementAPI")
    private let timeout: TimeInterval = 10

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Health / Config

    func checkHealth(baseURL: URL, password: String? = nil) async throws -> HealthResponse {
        let url = baseURL.appendingPathComponent("config")
        let data = try await performRequest(url: url, method: "GET", password: password)
        return try decode(HealthResponse.self, from: data)
    }

    // MARK: - API Keys

    func listAccounts(baseURL: URL, password: String? = nil) async throws -> [String] {
        let url = baseURL.appendingPathComponent("api-keys")
        let data = try await performRequest(url: url, method: "GET", password: password)
        return try decode([String].self, from: data)
    }

    func updateApiKeys(baseURL: URL, keys: [String], password: String? = nil) async throws -> [String] {
        let url = baseURL.appendingPathComponent("api-keys")
        let body = try JSONEncoder().encode(keys)
        let data = try await performRequest(url: url, method: "PUT", body: body, password: password)
        return try decode([String].self, from: data)
    }

    func deleteApiKey(baseURL: URL, index: Int, password: String? = nil) async throws {
        var components = URLComponents(url: baseURL.appendingPathComponent("api-keys"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "index", value: String(index))]
        _ = try await performRequest(url: components.url!, method: "DELETE", password: password)
    }

    // MARK: - Strategies

    func getStrategies(baseURL: URL, password: String? = nil) async throws -> StrategyDTO {
        let url = baseURL.appendingPathComponent("strategies")
        let data = try await performRequest(url: url, method: "GET", password: password)
        return try decode(StrategyDTO.self, from: data)
    }

    func updateStrategy(baseURL: URL, strategy: String, password: String? = nil) async throws -> StrategyDTO {
        let url = baseURL.appendingPathComponent("strategies")
        let request = UpdateStrategyRequest(strategy: strategy)
        let body = try JSONEncoder().encode(request)
        let data = try await performRequest(url: url, method: "PUT", body: body, password: password)
        return try decode(StrategyDTO.self, from: data)
    }

    // MARK: - Private

    private func performRequest(url: URL, method: String, body: Data? = nil, password: String? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body
        request.timeoutInterval = timeout

        // Add authentication header if password is provided
        if let password = password, !password.isEmpty {
            request.setValue("Bearer \(password)", forHTTPHeaderField: "Authorization")
        }

        logger.debug("\(method) \(url.absoluteString)")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ManagementAPIError.networkError(URLError(.badServerResponse))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let body = String(data: data, encoding: .utf8)
                logger.error("HTTP \(httpResponse.statusCode): \(body ?? "empty")")

                if httpResponse.statusCode == 401 {
                    throw ManagementAPIError.unauthorized
                }

                throw ManagementAPIError.httpError(statusCode: httpResponse.statusCode, body: body)
            }

            return data
        } catch let error as ManagementAPIError {
            throw error
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw ManagementAPIError.networkError(error)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            logger.error("Decoding error: \(error.localizedDescription)")
            throw ManagementAPIError.decodingError(error)
        }
    }
}

