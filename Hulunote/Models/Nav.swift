import Foundation

struct NavListResponse: Codable {
    let navList: [NavInfo]

    enum CodingKeys: String, CodingKey {
        case navList = "nav-list"
    }
}

struct NavPageResponse: Codable {
    let navList: [NavInfo]
    let allPages: Int?
    let backendTs: Int?

    enum CodingKeys: String, CodingKey {
        case navList = "nav-list"
        case allPages = "all-pages"
        case backendTs = "backend-ts"
    }
}

struct NavInfo: Codable, Identifiable {
    let id: String
    let parid: String?
    let sameDeepOrder: Float?
    let content: String
    let accountId: Int?
    let lastAccountId: Int?
    let noteId: String?
    let hulunoteNote: String?
    let databaseId: String?
    let isDisplay: Bool?
    let isPublic: Bool?
    let isDelete: Bool?
    let properties: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case parid
        case sameDeepOrder = "same-deep-order"
        case content
        case accountId = "account-id"
        case lastAccountId = "last-account-id"
        case noteId = "note-id"
        case hulunoteNote = "hulunote-note"
        case databaseId = "database-id"
        case isDisplay = "is-display"
        case isPublic = "is-public"
        case isDelete = "is-delete"
        case properties
        case createdAt = "created-at"
        case updatedAt = "updated-at"
    }
}

struct NavCreateRequest: Codable {
    let noteId: String
    let id: String?
    let parid: String?
    let content: String?
    let isDelete: Bool?
    let isDisplay: Bool?
    let order: Float?

    enum CodingKeys: String, CodingKey {
        case noteId = "note-id"
        case id, parid, content, order
        case isDelete = "is-delete"
        case isDisplay = "is-display"
    }
}

struct NavCreateResponse: Codable {
    let success: Bool
    let id: String?
    let nav: NavInfo?
    let backendTs: Int?

    enum CodingKeys: String, CodingKey {
        case success, id, nav
        case backendTs = "backend-ts"
    }
}

struct NavListRequest: Codable {
    let noteId: String

    enum CodingKeys: String, CodingKey {
        case noteId = "note-id"
    }
}
