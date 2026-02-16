import Foundation

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let email: String
    let password: String
    let username: String?
    let registrationCode: String?

    enum CodingKeys: String, CodingKey {
        case email, password, username
        case registrationCode = "registration_code"
    }
}

struct LoginResponse: Codable {
    let token: String
    let hulunote: AccountInfo
    let region: String?
}

struct SignupResponse: Codable {
    let token: String
    let hulunote: AccountInfo
    let database: String?
    let region: String?
}

struct AccountInfo: Codable {
    let id: Int
    let username: String?
    let nickname: String?
    let mail: String?
    let invitationCode: String?
    let isNewUser: Bool?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "accounts/id"
        case username = "accounts/username"
        case nickname = "accounts/nickname"
        case mail = "accounts/mail"
        case invitationCode = "accounts/invitation-code"
        case isNewUser = "accounts/is-new-user"
        case createdAt = "accounts/created-at"
        case updatedAt = "accounts/updated-at"
    }
}
