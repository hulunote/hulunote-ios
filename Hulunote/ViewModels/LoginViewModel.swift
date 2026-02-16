import Foundation

@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var error: String?

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    @MainActor
    func login() async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please enter your email"
            return
        }
        guard !password.isEmpty else {
            error = "Please enter your password"
            return
        }

        isLoading = true
        error = nil

        do {
            try await authService.login(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
