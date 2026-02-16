import Foundation

@Observable
final class DatabaseListViewModel {
    var databases: [DatabaseInfo] = []
    var isLoading = false
    var error: String?

    private let databaseService: DatabaseService
    private let authService: AuthService

    init(authService: AuthService, apiClient: APIClient) {
        self.databaseService = DatabaseService(api: apiClient)
        self.authService = authService
    }

    @MainActor
    func loadDatabases() async {
        isLoading = true
        error = nil
        do {
            let all = try await databaseService.getDatabaseList()
            databases = all.filter { $0.isDelete != true }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        authService.logout()
    }
}
