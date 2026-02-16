import Foundation

struct NoteListResponse: Codable {
    let noteList: [NoteInfo]
    let allPages: Int?

    enum CodingKeys: String, CodingKey {
        case noteList = "note-list"
        case allPages = "all-pages"
    }
}

struct NoteInfo: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let databaseId: String?
    let rootNavId: String?
    let isDelete: Bool?
    let isPublic: Bool?
    let isShortcut: Bool?
    let accountId: Int?
    let pv: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "hulunote-notes/id"
        case title = "hulunote-notes/title"
        case databaseId = "hulunote-notes/database-id"
        case rootNavId = "hulunote-notes/root-nav-id"
        case isDelete = "hulunote-notes/is-delete"
        case isPublic = "hulunote-notes/is-public"
        case isShortcut = "hulunote-notes/is-shortcut"
        case accountId = "hulunote-notes/account-id"
        case pv = "hulunote-notes/pv"
        case createdAt = "hulunote-notes/created-at"
        case updatedAt = "hulunote-notes/updated-at"
    }
}

struct NewNoteRequest: Codable {
    let databaseId: String
    let title: String

    enum CodingKeys: String, CodingKey {
        case databaseId = "database-id"
        case title
    }
}

struct NoteListRequest: Codable {
    let databaseId: String
    let page: Int
    let size: Int

    enum CodingKeys: String, CodingKey {
        case databaseId = "database-id"
        case page, size
    }
}

struct AllNoteListRequest: Codable {
    let databaseId: String

    enum CodingKeys: String, CodingKey {
        case databaseId = "database-id"
    }
}

struct UpdateNoteRequest: Codable {
    let noteId: String
    let title: String?
    let isDelete: Bool?
    let isShortcut: Bool?

    enum CodingKeys: String, CodingKey {
        case noteId = "note-id"
        case title
        case isDelete = "is-delete"
        case isShortcut = "is-shortcut"
    }
}
