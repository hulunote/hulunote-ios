import Foundation

@Observable
final class NoteListViewModel {
    var notes: [NoteInfo] = []
    var isLoading = false
    var error: String?
    var showCreateSheet = false
    var newNoteTitle = ""
    var searchText = ""
    var isCreating = false

    let databaseId: String
    private let noteService: NoteService

    var filteredNotes: [NoteInfo] {
        let active = notes.filter { $0.isDelete != true }
        if searchText.isEmpty { return active }
        return active.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    init(databaseId: String, apiClient: APIClient) {
        self.databaseId = databaseId
        self.noteService = NoteService(api: apiClient)
    }

    @MainActor
    func loadNotes() async {
        isLoading = true
        error = nil
        do {
            let response = try await noteService.getNoteList(databaseId: databaseId)
            notes = response.noteList
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func createNote() async {
        let title = newNoteTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }

        isCreating = true
        do {
            let note = try await noteService.createNote(databaseId: databaseId, title: title)
            notes.insert(note, at: 0)
            newNoteTitle = ""
            showCreateSheet = false
        } catch {
            self.error = error.localizedDescription
        }
        isCreating = false
    }

    @MainActor
    func deleteNote(noteId: String) async {
        do {
            try await noteService.updateNote(noteId: noteId, isDelete: true)
            notes.removeAll { $0.id == noteId }
        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    func toggleShortcut(noteId: String) async {
        guard let note = notes.first(where: { $0.id == noteId }) else { return }
        let newValue = !(note.isShortcut ?? false)
        do {
            try await noteService.updateNote(noteId: noteId, isShortcut: newValue)
            await loadNotes()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
