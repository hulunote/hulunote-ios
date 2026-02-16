import Foundation

struct NavService {
    let api: APIClient

    func getNavList(noteId: String) async throws -> [NavInfo] {
        let response: NavListResponse = try await api.post(
            path: "hulunote/get-note-navs",
            body: NavListRequest(noteId: noteId)
        )
        return response.navList
    }

    func createOrUpdateNav(request: NavCreateRequest) async throws -> NavCreateResponse {
        return try await api.post(
            path: "hulunote/create-or-update-nav",
            body: request
        )
    }

    func createNav(noteId: String, parid: String, content: String, order: Float) async throws -> NavCreateResponse {
        return try await createOrUpdateNav(request: NavCreateRequest(
            noteId: noteId,
            id: nil,
            parid: parid,
            content: content,
            isDelete: nil,
            isDisplay: true,
            order: order
        ))
    }

    func updateNavContent(noteId: String, navId: String, content: String) async throws -> NavCreateResponse {
        return try await createOrUpdateNav(request: NavCreateRequest(
            noteId: noteId,
            id: navId,
            parid: nil,
            content: content,
            isDelete: nil,
            isDisplay: nil,
            order: nil
        ))
    }

    func updateNavParent(noteId: String, navId: String, newParid: String, order: Float) async throws -> NavCreateResponse {
        return try await createOrUpdateNav(request: NavCreateRequest(
            noteId: noteId,
            id: navId,
            parid: newParid,
            content: nil,
            isDelete: nil,
            isDisplay: nil,
            order: order
        ))
    }

    func deleteNav(noteId: String, navId: String) async throws -> NavCreateResponse {
        return try await createOrUpdateNav(request: NavCreateRequest(
            noteId: noteId,
            id: navId,
            parid: nil,
            content: nil,
            isDelete: true,
            isDisplay: nil,
            order: nil
        ))
    }
}
