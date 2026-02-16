import Foundation

@Observable
final class AppViewModel {
    let authService: AuthService

    var isLoggedIn: Bool { authService.isLoggedIn }

    init(baseURL: URL = URL(string: "https://www.hulunote.top")!) {
        self.authService = AuthService(baseURL: baseURL)
    }

    var apiClient: APIClient {
        authService.apiClient
    }

    func logout() {
        authService.logout()
    }
}
