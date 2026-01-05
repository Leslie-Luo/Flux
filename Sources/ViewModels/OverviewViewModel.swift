import Foundation
import os.log

@MainActor
final class OverviewViewModel: ObservableObject {
    @Published var healthState: LoadState<HealthResponse> = .idle
    @Published var apiKeysState: LoadState<[String]> = .idle

    private let client = ManagementAPIClient()
    private let logger = Logger(subsystem: "com.flux.app", category: "OverviewVM")

    func refresh(baseURL: URL, password: String?) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.checkHealth(baseURL: baseURL, password: password) }
            group.addTask { await self.refreshApiKeys(baseURL: baseURL, password: password) }
        }
    }

    private func checkHealth(baseURL: URL, password: String?) async {
        healthState = .loading
        do {
            let response = try await client.checkHealth(baseURL: baseURL, password: password)
            healthState = .loaded(response)
        } catch {
            healthState = .error(error.localizedDescription)
        }
    }

    private func refreshApiKeys(baseURL: URL, password: String?) async {
        apiKeysState = .loading
        do {
            let keys = try await client.listAccounts(baseURL: baseURL, password: password)
            apiKeysState = .loaded(keys)
        } catch {
            apiKeysState = .error(error.localizedDescription)
        }
    }
}
