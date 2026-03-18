import Foundation

@MainActor
@Observable
final class BookkeepingViewModel {
    var entries: [BookkeepingEntry] = []
    var isLoading = false
    var error: String?

    // Input state
    var inputText = ""
    var parsedAmount: Double?
    var parsedCategory: BookkeepingCategory = .other
    var parsedDescription = ""
    var isIncome = false
    var showConfirmSheet = false

    // Stats
    var statsPeriod: StatsPeriod = .month
    var allEntries: [BookkeepingEntry] = []
    var showStats = false

    let databaseId: String
    let speechService = SpeechService()
    private let noteService: NoteService
    private let navService: NavService

    private var dailyNoteId: String?
    private var dailyRootNavId: String?
    private var allNotes: [NoteInfo] = []

    private static let noteTitlePrefix = "账本-"

    init(databaseId: String, apiClient: APIClient) {
        self.databaseId = databaseId
        self.noteService = NoteService(api: apiClient)
        self.navService = NavService(api: apiClient)
    }

    // MARK: - Daily Note Title

    private static func dailyNoteTitle(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(noteTitlePrefix)\(formatter.string(from: date))"
    }

    // MARK: - Load Today's Entries

    func loadToday() async {
        isLoading = true
        error = nil
        do {
            allNotes = try await noteService.getAllNotes(databaseId: databaseId)
            let todayTitle = Self.dailyNoteTitle()

            // Find or create today's note
            if let existingNote = allNotes.first(where: { $0.title == todayTitle && $0.isDelete != true }) {
                dailyNoteId = existingNote.id
                dailyRootNavId = existingNote.rootNavId
            } else {
                let newNote = try await noteService.createNote(databaseId: databaseId, title: todayTitle)
                dailyNoteId = newNote.id
                dailyRootNavId = newNote.rootNavId
                allNotes.append(newNote)
            }

            // Load entries from today's note
            if let noteId = dailyNoteId {
                let navs = try await navService.getNavList(noteId: noteId)
                entries = navs.compactMap { BookkeepingEntry.parse(from: $0) }
                    .sorted { $0.date > $1.date }

                // Find root nav if not set
                if dailyRootNavId == nil {
                    let nilUUID = OutlineTreeBuilder.nilUUID
                    let rootNav = navs.first { nav in
                        nav.parid == nil
                            || nav.parid == nilUUID
                            || nav.parid == nav.id
                            || nav.parid?.isEmpty == true
                    }
                    dailyRootNavId = rootNav?.id
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Parse Voice Input

    func parseInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        parsedAmount = AmountParser.parse(from: text)
        parsedCategory = BookkeepingCategory.detect(from: text)
        parsedDescription = AmountParser.extractDescription(from: text)
        isIncome = AmountParser.isIncome(from: text)

        if parsedDescription.isEmpty {
            parsedDescription = text
        }

        showConfirmSheet = true
    }

    // MARK: - Save Entry

    func saveEntry() async {
        guard let amount = parsedAmount, amount > 0 else {
            error = "请输入有效金额"
            return
        }
        guard let noteId = dailyNoteId, let rootId = dailyRootNavId else {
            error = "无法找到今日账本"
            return
        }

        let entry = BookkeepingEntry(
            id: UUID().uuidString,
            description: parsedDescription,
            amount: amount,
            category: parsedCategory,
            isIncome: isIncome,
            date: Date(),
            navId: ""
        )

        // Calculate order
        let siblingCount = entries.count
        let newOrder = Float((siblingCount + 1) * 100)

        do {
            let response = try await navService.createNav(
                noteId: noteId,
                parid: rootId,
                content: entry.formattedContent,
                order: newOrder
            )

            if let nav = response.nav, let saved = BookkeepingEntry.parse(from: nav) {
                entries.insert(saved, at: 0)
            }

            // Reset input
            inputText = ""
            parsedAmount = nil
            parsedDescription = ""
            parsedCategory = .other
            isIncome = false
            showConfirmSheet = false
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Delete Entry

    func deleteEntry(_ entry: BookkeepingEntry) async {
        guard let noteId = dailyNoteId else { return }
        do {
            _ = try await navService.deleteNav(noteId: noteId, navId: entry.navId)
            entries.removeAll { $0.id == entry.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Voice

    func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
            let text = speechService.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                inputText = text
                parseInput()
            }
        } else {
            Task {
                await speechService.startRecording()
            }
        }
    }

    // MARK: - Load All Entries for Stats

    func loadAllEntries() async {
        isLoading = true
        do {
            if allNotes.isEmpty {
                allNotes = try await noteService.getAllNotes(databaseId: databaseId)
            }

            let bookNotes = allNotes.filter {
                $0.title.hasPrefix(Self.noteTitlePrefix) && $0.isDelete != true
            }

            var all: [BookkeepingEntry] = []
            for note in bookNotes {
                let navs = try await navService.getNavList(noteId: note.id)
                let noteEntries = navs.compactMap { BookkeepingEntry.parse(from: $0) }
                all.append(contentsOf: noteEntries)
            }

            // Also parse date from note title for entries without createdAt
            for (index, entry) in all.enumerated() {
                if let note = bookNotes.first(where: { $0.id == entry.navId }) {
                    // Try to use note title date
                    let titleDate = note.title.replacingOccurrences(of: Self.noteTitlePrefix, with: "")
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let date = formatter.date(from: titleDate) {
                        all[index] = BookkeepingEntry(
                            id: entry.id, description: entry.description,
                            amount: entry.amount, category: entry.category,
                            isIncome: entry.isIncome, date: date, navId: entry.navId
                        )
                    }
                }
            }

            allEntries = all.sorted { $0.date > $1.date }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Stats Computation

    var filteredEntries: [BookkeepingEntry] {
        let calendar = Calendar.current
        let now = Date()

        return allEntries.filter { entry in
            switch statsPeriod {
            case .week:
                return calendar.isDate(entry.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(entry.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(entry.date, equalTo: now, toGranularity: .year)
            }
        }
    }

    var totalExpense: Double {
        filteredEntries.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    var totalIncome: Double {
        filteredEntries.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    var categoryBreakdown: [(category: BookkeepingCategory, amount: Double)] {
        var dict: [BookkeepingCategory: Double] = [:]
        for entry in filteredEntries where !entry.isIncome {
            dict[entry.category, default: 0] += entry.amount
        }
        return dict.map { ($0.key, $0.value) }.sorted { $0.amount > $1.amount }
    }

    // MARK: - Today Summary

    var todayExpense: Double {
        entries.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    var todayIncome: Double {
        entries.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }
}
