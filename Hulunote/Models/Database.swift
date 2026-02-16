import Foundation

struct DatabaseListResponse: Codable {
    let databaseList: [DatabaseInfo]

    enum CodingKeys: String, CodingKey {
        case databaseList = "database-list"
    }
}

struct DatabaseInfo: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let isDelete: Bool?
    let isPublic: Bool?
    let isDefault: Bool?
    let accountId: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "hulunote-databases/id"
        case name = "hulunote-databases/name"
        case description = "hulunote-databases/description"
        case isDelete = "hulunote-databases/is-delete"
        case isPublic = "hulunote-databases/is-public"
        case isDefault = "hulunote-databases/is-default"
        case accountId = "hulunote-databases/account-id"
        case createdAt = "hulunote-databases/created-at"
        case updatedAt = "hulunote-databases/updated-at"
    }
}

struct NewDatabaseRequest: Codable {
    let databaseName: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case databaseName = "database-name"
        case description
    }
}

struct UpdateDatabaseRequest: Codable {
    let databaseId: String
    let dbName: String?
    let isPublic: Bool?
    let isDefault: Bool?
    let isDelete: Bool?

    enum CodingKeys: String, CodingKey {
        case databaseId = "database-id"
        case dbName = "db-name"
        case isPublic = "is-public"
        case isDefault = "is-default"
        case isDelete = "is-delete"
    }
}
