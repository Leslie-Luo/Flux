import Foundation
import os.log

enum LoadState<T: Equatable>: Equatable {
    case idle
    case loading
    case loaded(T)
    case error(String)
}

@MainActor
final class ManagementViewModel: ObservableObject {
    @Published var healthState: LoadState<HealthResponse> = .idle
    @Published var apiKeysState: LoadState<[String]> = .idle
    @Published var strategiesState: LoadState<StrategyDTO> = .idle

    private let client = ManagementAPIClient()
    private let logger = Logger(subsystem: "com.flux.app", category: "ManagementVM")

    func checkHealth(baseURL: URL, password: String?) async {
        healthState = .loading
        do {
            let response = try await client.checkHealth(baseURL: baseURL, password: password)
            healthState = .loaded(response)
            logger.info("Health check passed: \(response.status)")
        } catch {
            healthState = .error(error.localizedDescription)
            logger.error("Health check failed: \(error.localizedDescription)")
        }
    }

    func refreshApiKeys(baseURL: URL, password: String?) async {
        apiKeysState = .loading
        do {
            let keys = try await client.listAccounts(baseURL: baseURL, password: password)
            apiKeysState = .loaded(keys)
        } catch {
            apiKeysState = .error(error.localizedDescription)
        }
    }

    func updateApiKeys(baseURL: URL, keys: [String], password: String?) async {
        do {
            let updated = try await client.updateApiKeys(baseURL: baseURL, keys: keys, password: password)
            apiKeysState = .loaded(updated)
        } catch {
            logger.error("Update API keys failed: \(error.localizedDescription)")
        }
    }

    func deleteApiKey(baseURL: URL, index: Int, password: String?) async {
        do {
            try await client.deleteApiKey(baseURL: baseURL, index: index, password: password)
            await refreshApiKeys(baseURL: baseURL, password: password)
        } catch {
            logger.error("Delete API key failed: \(error.localizedDescription)")
        }
    }

    func refreshStrategies(baseURL: URL, password: String?) async {
        strategiesState = .loading
        do {
            let strategies = try await client.getStrategies(baseURL: baseURL, password: password)
            strategiesState = .loaded(strategies)
        } catch {
            strategiesState = .error(error.localizedDescription)
        }
    }

    func updateStrategy(baseURL: URL, strategy: String, password: String?) async {
        do {
            let updated = try await client.updateStrategy(baseURL: baseURL, strategy: strategy, password: password)
            strategiesState = .loaded(updated)
        } catch {
            logger.error("Update strategy failed: \(error.localizedDescription)")
        }
    }

    func refreshAll(baseURL: URL, password: String?) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.checkHealth(baseURL: baseURL, password: password) }
            group.addTask { await self.refreshApiKeys(baseURL: baseURL, password: password) }
            group.addTask { await self.refreshStrategies(baseURL: baseURL, password: password) }
        }
    }
}
