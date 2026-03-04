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

    let databaseId: String
    let databaseName: String
    private let noteService: NoteService
    private let navService: NavService
    private let synth = AVSpeechSynthesizer()

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

            // 2. Load all nav blocks for each note
            var allContent: [String] = []
            for note in activeNotes {
                let navs = try await navService.getNavList(noteId: note.id)
                let contents = navs
                    .filter { $0.isDelete != true && $0.content != "ROOT" && !$0.content.isEmpty }
                    .map { $0.content }
                allContent.append(contentsOf: contents)
            }

            // 3. Parse words and filter known words
            let knownWords = loadKnownWords()
            let parsed = parseWords(from: allContent)
            let newWords = parsed.filter { !knownWords.contains($0.lowercased()) }

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
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utterance)
    }

    // MARK: - Word Parsing

    private func parseWords(from contents: [String]) -> [String] {
        let separators = CharacterSet(charactersIn: " .)/(\",：:[];_-@*#!?{}|<>~`+=%&^$\n\r\t")
        return contents
            .flatMap { $0.components(separatedBy: separators) }
            .filter { $0.rangeOfCharacter(from: .letters) != nil }
            .filter { $0.count > 1 } // skip single chars
    }

    private func loadKnownWords() -> Set<String> {
        guard let url = Bundle.main.url(forResource: "knowed-word", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return Set(content.lowercased().components(separatedBy: .newlines).filter { !$0.isEmpty })
    }
}
