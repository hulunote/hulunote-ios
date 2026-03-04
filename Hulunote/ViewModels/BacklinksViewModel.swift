import Foundation

struct BacklinkItem: Identifiable {
    let id = UUID()
    let noteId: String
    let noteTitle: String
    let rootNavId: String?
    let blockContent: String
}

@Observable
final class BacklinksViewModel {
    var backlinks: [BacklinkItem] = []
    var isLoading = false

    private let noteTitle: String
    private let noteId: String
    private let databaseId: String
    private let noteService: NoteService
    private let navService: NavService

    init(noteTitle: String, noteId: String, databaseId: String, apiClient: APIClient) {
        self.noteTitle = noteTitle
        self.noteId = noteId
        self.databaseId = databaseId
        self.noteService = NoteService(api: apiClient)
        self.navService = NavService(api: apiClient)
    }

    @MainActor
    func loadBacklinks() async {
        isLoading = true
        defer { isLoading = false }

        let searchPattern = "[[\(noteTitle)]]"

        do {
            let allNotes = try await noteService.getAllNotes(databaseId: databaseId)
            let otherNotes = allNotes.filter { $0.id != noteId && $0.isDelete != true }

            var results: [BacklinkItem] = []

            for note in otherNotes {
                do {
                    let navs = try await navService.getNavList(noteId: note.id)
                    let matchingNavs = navs.filter { nav in
                        nav.isDelete != true && nav.content.contains(searchPattern)
                    }
                    for nav in matchingNavs {
                        results.append(BacklinkItem(
                            noteId: note.id,
                            noteTitle: note.title,
                            rootNavId: note.rootNavId,
                            blockContent: nav.content
                        ))
                    }
                } catch {
                    // Skip notes that fail to load
                    continue
                }
            }

            self.backlinks = results
        } catch {
            // Failed to load notes list
        }
    }
}
