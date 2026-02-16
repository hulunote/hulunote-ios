import Foundation

struct NoteService {
    let api: APIClient

    func getNoteList(databaseId: String, page: Int = 1, size: Int = 100) async throws -> NoteListResponse {
        return try await api.post(
            path: "hulunote/get-note-list",
            body: NoteListRequest(databaseId: databaseId, page: page, size: size)
        )
    }

    func getAllNotes(databaseId: String) async throws -> [NoteInfo] {
        let response: NoteListResponse = try await api.post(
            path: "hulunote/get-all-note-list",
            body: AllNoteListRequest(databaseId: databaseId)
        )
        return response.noteList
    }

    func createNote(databaseId: String, title: String) async throws -> NoteInfo {
        return try await api.post(
            path: "hulunote/new-note",
            body: NewNoteRequest(databaseId: databaseId, title: title)
        )
    }

    func updateNote(noteId: String, title: String? = nil, isDelete: Bool? = nil, isShortcut: Bool? = nil) async throws {
        let _: NoteInfo = try await api.post(
            path: "hulunote/update-hulunote-note",
            body: UpdateNoteRequest(noteId: noteId, title: title, isDelete: isDelete, isShortcut: isShortcut)
        )
    }

    func getShortcutNotes(databaseId: String) async throws -> [NoteInfo] {
        let response: NoteListResponse = try await api.post(
            path: "hulunote/get-shortcuts-note-list",
            body: AllNoteListRequest(databaseId: databaseId)
        )
        return response.noteList
    }
}
