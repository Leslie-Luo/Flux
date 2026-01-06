import Foundation
import os.log

@MainActor
final class AuthFilesViewModel: ObservableObject {
    @Published var authFilesState: LoadState<[AuthFile]> = .idle

    private let client = ManagementAPIClient()
    private let logger = Logger(subsystem: "com.flux.app", category: "AuthFilesVM")

    func refresh(baseURL: URL, password: String?) async {
        authFilesState = .loading
        do {
            let response = try await client.getAuthFiles(baseURL: baseURL, password: password)
            authFilesState = .loaded(response.files ?? [])
            logger.info("Auth files loaded: \(response.files?.count ?? 0)")
        } catch {
            authFilesState = .error(error.localizedDescription)
            logger.error("Failed to load auth files: \(error.localizedDescription)")
        }
    }
}