import Foundation
import AVFoundation

@Observable
final class WordLearningViewModel {
    var words: [String] = []
    var currentIndex: Int = 0
    var isLoading = false
    var error: String?
    var currentWord: String = ""
    var totalCount: Int = 0
    var isSaving = false

    let databaseId: String
    let databaseName: String
    private let noteService: NoteService
    private let navService: NavService
    private let synth = AVSpeechSynthesizer()

    private var memorizedNoteId: String?
    private var memorizedRootNavId: String?

    init(databaseId: String, databaseName: String, apiClient: APIClient) {
        self.databaseId = databaseId
        self.databaseName = databaseName
        self.noteService = NoteService(api: apiClient)
        self.navService = NavService(api: apiClient)
    }

    // MARK: - Load Words

    @MainActor
    func loadWords() async {
        isLoading = true
        error = nil
        do {
            // 1. Load all notes in this database
            let notes = try await noteService.getAllNotes(databaseId: databaseId)
            let activeNotes = notes.filter { $0.isDelete != true }

            // 2. Find or create "Memorized Words" note
            let memorizedWords = try await loadMemorizedWords(from: activeNotes)

            // 3. Load all nav blocks from OTHER notes (not the memorized words note)
            var allContent: [String] = []
            for note in activeNotes where note.id != memorizedNoteId {
                let navs = try await navService.getNavList(noteId: note.id)
                let contents = navs
                    .filter { $0.isDelete != true && $0.content != "ROOT" && !$0.content.isEmpty }
                    .map { $0.content }
                allContent.append(contentsOf: contents)
            }

            // 4. Parse English-only words and filter memorized ones
            let parsed = parseWords(from: allContent)
            let newWords = parsed.filter { !memorizedWords.contains($0.lowercased()) }

            // Remove duplicates while preserving order
            var seen = Set<String>()
            self.words = newWords.filter { word in
                let lower = word.lowercased()
                if seen.contains(lower) { return false }
                seen.insert(lower)
                return true
            }
            self.totalCount = self.words.count
            self.currentIndex = 0
            if !words.isEmpty {
                self.currentWord = words[0]
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Memorized Words Note

    private func loadMemorizedWords(from notes: [NoteInfo]) async throws -> Set<String> {
        // Find existing "Memorized Words" note
        if let existingNote = notes.first(where: { $0.title == "Memorized Words" }) {
            memorizedNoteId = existingNote.id
            memorizedRootNavId = existingNote.rootNavId

            let navs = try await navService.getNavList(noteId: existingNote.id)
            // Find root nav id if not set
            if memorizedRootNavId == nil {
                let nilUUID = OutlineTreeBuilder.nilUUID
                let rootNav = navs.first { nav in
                    nav.parid == nil
                        || nav.parid == nilUUID
                        || nav.parid == nav.id
                        || nav.parid?.isEmpty == true
                }
                memorizedRootNavId = rootNav?.id
            }

            let words = navs
                .filter { $0.isDelete != true && $0.content != "ROOT" && !$0.content.isEmpty }
                .map { $0.content.lowercased().trimmingCharacters(in: .whitespaces) }
            return Set(words)
        }

        // Create "Memorized Words" note if it doesn't exist
        let newNote = try await noteService.createNote(databaseId: databaseId, title: "Memorized Words")
        memorizedNoteId = newNote.id
        memorizedRootNavId = newNote.rootNavId

        // Load navs to get root nav id
        if memorizedRootNavId == nil {
            let navs = try await navService.getNavList(noteId: newNote.id)
            let nilUUID = OutlineTreeBuilder.nilUUID
            let rootNav = navs.first { nav in
                nav.parid == nil
                    || nav.parid == nilUUID
                    || nav.parid == nav.id
                    || nav.parid?.isEmpty == true
            }
            memorizedRootNavId = rootNav?.id
        }

        return []
    }

    // MARK: - Mark as Remembered

    @MainActor
    func markAsRemembered() async {
        guard !currentWord.isEmpty,
              let noteId = memorizedNoteId,
              let rootId = memorizedRootNavId else { return }

        isSaving = true
        do {
            // Save word to "Memorized Words" note
            _ = try await navService.createNav(
                noteId: noteId,
                parid: rootId,
                content: currentWord,
                order: Float(Date().timeIntervalSince1970)
            )

            // Remove from current list
            if let idx = words.firstIndex(where: { $0.lowercased() == currentWord.lowercased() }) {
                words.remove(at: idx)
                totalCount = words.count

                // Adjust index
                if currentIndex > idx {
                    currentIndex -= 1
                }
                if currentIndex >= totalCount {
                    currentIndex = 0
                }

                // Show next word
                if !words.isEmpty {
                    currentWord = words[currentIndex]
                    speak(currentWord)
                } else {
                    currentWord = ""
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }

    // MARK: - TTS

    func speakNext() {
        guard !words.isEmpty else { return }
        if currentIndex >= totalCount {
            currentIndex = 0
        }
        currentWord = words[currentIndex]
        speak(currentWord)
        currentIndex += 1
    }

    func speakCurrent() {
        guard !currentWord.isEmpty else { return }
        speak(currentWord)
    }

    func speakPrevious() {
        guard !words.isEmpty else { return }
        currentIndex = max(0, currentIndex - 2)
        currentWord = words[currentIndex]
        speak(currentWord)
        currentIndex += 1
    }

    func speakAll() {
        for word in words {
            speak(word)
        }
    }

    private func speak(_ text: String) {
        // Configure audio session for playback - required on real iPhone devices
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utterance)
    }

    // MARK: - Word Parsing (English-only)

    private func parseWords(from contents: [String]) -> [String] {
        let separators = CharacterSet(charactersIn: " .)/(\",：:[];_-@*#!?{}|<>~`+=%&^$\n\r\t")
        return contents
            .flatMap { $0.components(separatedBy: separators) }
            .filter { $0.count > 1 }
            .filter { $0.allSatisfy { $0.isASCII && $0.isLetter } } // English letters only
    }
}
