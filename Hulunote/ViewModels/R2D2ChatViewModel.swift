import Foundation

/// A chat message derived from a NavInfo node for R2D2 display.
struct R2D2Message: Identifiable {
    let id: String
    let content: String
    let parid: String?
    let createdAt: String?
    let replyToContent: String?  // content of the parent message (if replying)
}

@Observable
final class R2D2ChatViewModel {
    var messages: [R2D2Message] = []
    var inputText = ""
    var replyingTo: R2D2Message?
    var isLoading = false
    var error: String?
    var rootNavId: String?

    let noteId: String
    let noteTitle: String
    private let navService: NavService
    private var navList: [NavInfo] = []

    init(noteId: String, noteTitle: String, rootNavId: String?, apiClient: APIClient) {
        self.noteId = noteId
        self.noteTitle = noteTitle
        self.rootNavId = rootNavId
        self.navService = NavService(api: apiClient)
    }

    // MARK: - Load

    @MainActor
    func loadMessages() async {
        isLoading = true
        error = nil
        do {
            let navs = try await navService.getNavList(noteId: noteId)
            self.navList = navs

            // Find root nav if not already set
            if rootNavId == nil {
                let nilUUID = OutlineTreeBuilder.nilUUID
                let rootNav = navs.first { nav in
                    nav.parid == nil
                        || nav.parid == nilUUID
                        || nav.parid == nav.id
                        || nav.parid?.isEmpty == true
                }
                self.rootNavId = rootNav?.id
            }

            rebuildMessages()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func rebuildMessages() {
        let nilUUID = OutlineTreeBuilder.nilUUID
        let contentMap = Dictionary(
            navList.filter { $0.isDelete != true }.map { ($0.id, $0.content) },
            uniquingKeysWith: { _, last in last }
        )

        messages = navList
            .filter { nav in
                nav.isDelete != true
                    && nav.content != "ROOT"
                    && nav.id != rootNavId
                    && nav.parid != nil
                    && nav.parid != nilUUID
                    && nav.parid != nav.id
            }
            .sorted { a, b in
                (a.createdAt ?? "") < (b.createdAt ?? "")
            }
            .map { nav in
                let replyContent: String?
                if let parid = nav.parid, parid != rootNavId {
                    replyContent = contentMap[parid]
                } else {
                    replyContent = nil
                }
                return R2D2Message(
                    id: nav.id,
                    content: nav.content,
                    parid: nav.parid,
                    createdAt: nav.createdAt,
                    replyToContent: replyContent
                )
            }
    }

    // MARK: - Send Message

    @MainActor
    func sendMessage() async {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        guard let rootId = rootNavId else { return }

        let parid = replyingTo?.id ?? rootId

        // Calculate order: append at the end of parent's children
        let siblingOrders = navList
            .filter { $0.parid == parid && $0.isDelete != true }
            .compactMap { $0.sameDeepOrder }
        let maxOrder = siblingOrders.max() ?? 0
        let newOrder = maxOrder + 100

        inputText = ""
        replyingTo = nil

        do {
            let response = try await navService.createNav(
                noteId: noteId,
                parid: parid,
                content: content,
                order: newOrder
            )
            if let nav = response.nav {
                navList.append(nav)
                rebuildMessages()
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Delete Message

    @MainActor
    func deleteMessage(messageId: String) async {
        do {
            _ = try await navService.deleteNav(noteId: noteId, navId: messageId)
            navList = navList.map { nav in
                if nav.id == messageId {
                    return NavInfo(
                        id: nav.id, parid: nav.parid, sameDeepOrder: nav.sameDeepOrder,
                        content: nav.content, accountId: nav.accountId, lastAccountId: nav.lastAccountId,
                        noteId: nav.noteId, hulunoteNote: nav.hulunoteNote, databaseId: nav.databaseId,
                        isDisplay: nav.isDisplay, isPublic: nav.isPublic, isDelete: true,
                        properties: nav.properties, createdAt: nav.createdAt, updatedAt: nav.updatedAt
                    )
                }
                return nav
            }
            rebuildMessages()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Reply

    func startReply(to message: R2D2Message) {
        replyingTo = message
    }

    func cancelReply() {
        replyingTo = nil
    }
}
