import Foundation

@Observable
final class AuthService {
    private let keychain: KeychainService
    private(set) var token: String?
    private(set) var account: AccountInfo?

    private(set) var apiClient: APIClient

    var isLoggedIn: Bool { token != nil }

    init(baseURL: URL = URL(string: "https://www.hulunote.top")!) {
        let keychain = KeychainService()
        self.keychain = keychain
        let savedToken = keychain.read(key: "jwt_token")
        self.token = savedToken

        // Capture token in a thread-safe way for the closure
        let tokenBox = TokenBox()
        tokenBox.token = savedToken
        self.apiClient = APIClient(baseURL: baseURL, tokenProvider: { tokenBox.token })
        self._tokenBox = tokenBox
    }

    private let _tokenBox: TokenBox

    func login(email: String, password: String) async throws {
        let response: LoginResponse = try await apiClient.post(
            path: "login/web-login",
            body: LoginRequest(email: email, password: password)
        )
        self.token = response.token
        self.account = response.hulunote
        self._tokenBox.token = response.token
        keychain.save(key: "jwt_token", value: response.token)
    }

    func signup(email: String, password: String, registrationCode: String?) async throws {
        let response: SignupResponse = try await apiClient.post(
            path: "login/web-signup",
            body: SignupRequest(email: email, password: password, username: nil, registrationCode: registrationCode)
        )
        self.token = response.token
        self.account = response.hulunote
        self._tokenBox.token = response.token
        keychain.save(key: "jwt_token", value: response.token)
    }

    func logout() {
        self.token = nil
        self.account = nil
        self._tokenBox.token = nil
        keychain.delete(key: "jwt_token")
    }
}

// Thread-safe mutable token holder for the APIClient closure
private final class TokenBox: @unchecked Sendable {
    var token: String?
}
