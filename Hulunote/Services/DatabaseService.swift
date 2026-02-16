import Foundation

struct DatabaseService {
    let api: APIClient

    func getDatabaseList() async throws -> [DatabaseInfo] {
        let response: DatabaseListResponse = try await api.post(path: "hulunote/get-database-list")
        return response.databaseList
    }

    func createDatabase(name: String, description: String? = nil) async throws -> DatabaseInfo {
        return try await api.post(
            path: "hulunote/new-database",
            body: NewDatabaseRequest(databaseName: name, description: description)
        )
    }

    func updateDatabase(id: String, name: String? = nil, isPublic: Bool? = nil, isDefault: Bool? = nil) async throws {
        let _: DatabaseInfo = try await api.post(
            path: "hulunote/update-database",
            body: UpdateDatabaseRequest(databaseId: id, dbName: name, isPublic: isPublic, isDefault: isDefault, isDelete: nil)
        )
    }

    func deleteDatabase(id: String) async throws {
        let _: DatabaseInfo = try await api.post(
            path: "hulunote/delete-database",
            body: UpdateDatabaseRequest(databaseId: id, dbName: nil, isPublic: nil, isDefault: nil, isDelete: true)
        )
    }
}
