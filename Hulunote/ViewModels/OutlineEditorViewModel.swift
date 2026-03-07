import Foundation
import UIKit

@Observable
final class OutlineEditorViewModel {
    var navList: [NavInfo] = []
    var displayList: [OutlineNode] = []
    var rootNavId: String?
    var isLoading = false
    var error: String?
    var focusNodeId: String?
    var collapsedIds: Set<String> = []

    let noteId: String
    let noteTitle: String
    private let navService: NavService
    private var saveDebounceTask: [String: Task<Void, Never>] = [:]

    init(noteId: String, noteTitle: String, rootNavId: String?, apiClient: APIClient) {
        self.noteId = noteId
        self.noteTitle = noteTitle
        self.rootNavId = rootNavId
        self.navService = NavService(api: apiClient)
    }

    // MARK: - Load

    @MainActor
    func loadNavs() async {
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

            rebuildDisplayList()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func rebuildDisplayList() {
        displayList = OutlineTreeBuilder.buildDisplayList(
            navList: navList,
            rootNavId: rootNavId,
            collapsedIds: collapsedIds
        )
    }

    // MARK: - Content Editing

    func onContentChange(navId: String, content: String) {
        // Optimistic local update
        navList = navList.map { nav in
            if nav.id == navId {
                return NavInfo(
                    id: nav.id, parid: nav.parid, sameDeepOrder: nav.sameDeepOrder,
                    content: content, accountId: nav.accountId, lastAccountId: nav.lastAccountId,
                    noteId: nav.noteId, hulunoteNote: nav.hulunoteNote, databaseId: nav.databaseId,
                    isDisplay: nav.isDisplay, isPublic: nav.isPublic, isDelete: nav.isDelete,
                    properties: nav.properties, createdAt: nav.createdAt, updatedAt: nav.updatedAt
                )
            }
            return nav
        }
        rebuildDisplayList()

        // Debounced server save (500ms)
        saveDebounceTask[navId]?.cancel()
        saveDebounceTask[navId] = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            _ = try? await self.navService.updateNavContent(
                noteId: self.noteId, navId: navId, content: content
            )
        }
    }

    // MARK: - Create Block

    @MainActor
    func createNewBlock(afterNodeId: String) async {
        guard let index = displayList.firstIndex(where: { $0.id == afterNodeId }) else { return }
        let currentNode = displayList[index]
        let parid = currentNode.parid ?? rootNavId ?? ""

        // Calculate order: between current and next sibling
        let nextSibling = OutlineTreeBuilder.findNextSibling(in: displayList, at: index)
        let newOrder = OutlineTreeBuilder.orderBetween(
            prev: currentNode.order,
            next: nextSibling?.order
        )

        do {
            let response = try await navService.createNav(
                noteId: noteId,
                parid: parid,
                content: "",
                order: newOrder
            )
            if let nav = response.nav {
                navList.append(nav)
                rebuildDisplayList()
                // Focus the new block
                focusNodeId = nav.id
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    func createFirstBlock() async {
        guard let rootId = rootNavId else { return }
        do {
            let response = try await navService.createNav(
                noteId: noteId,
                parid: rootId,
                content: "",
                order: 100
            )
            if let nav = response.nav {
                navList.append(nav)
                rebuildDisplayList()
                focusNodeId = nav.id
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Delete Block

    @MainActor
    func deleteBlock(navId: String) async {
        guard let index = displayList.firstIndex(where: { $0.id == navId }) else { return }

        // Find the block to focus after deletion
        let focusAfterDelete: String?
        if index > 0 {
            focusAfterDelete = displayList[index - 1].id
        } else if displayList.count > 1 {
            focusAfterDelete = displayList[1].id
        } else {
            focusAfterDelete = nil
        }

        do {
            _ = try await navService.deleteNav(noteId: noteId, navId: navId)
            navList = navList.map { nav in
                if nav.id == navId {
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
            rebuildDisplayList()
            focusNodeId = focusAfterDelete
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Indent (make child of previous sibling)

    @MainActor
    func indentBlock(navId: String) async {
        guard let index = displayList.firstIndex(where: { $0.id == navId }) else { return }
        guard let prevSibling = OutlineTreeBuilder.findPreviousSibling(in: displayList, at: index) else { return }

        // Move this node under the previous sibling
        let newParid = prevSibling.id

        // Find last child of the new parent to calculate order
        let childrenOfNewParent = navList.filter {
            $0.parid == newParid && $0.isDelete != true
        }.sorted { ($0.sameDeepOrder ?? 0) < ($1.sameDeepOrder ?? 0) }

        let lastChildOrder = childrenOfNewParent.last?.sameDeepOrder
        let newOrder = (lastChildOrder ?? 0) + 100

        do {
            _ = try await navService.updateNavParent(
                noteId: noteId, navId: navId, newParid: newParid, order: newOrder
            )
            // Update local state
            navList = navList.map { nav in
                if nav.id == navId {
                    return NavInfo(
                        id: nav.id, parid: newParid, sameDeepOrder: newOrder,
                        content: nav.content, accountId: nav.accountId, lastAccountId: nav.lastAccountId,
                        noteId: nav.noteId, hulunoteNote: nav.hulunoteNote, databaseId: nav.databaseId,
                        isDisplay: nav.isDisplay, isPublic: nav.isPublic, isDelete: nav.isDelete,
                        properties: nav.properties, createdAt: nav.createdAt, updatedAt: nav.updatedAt
                    )
                }
                return nav
            }
            // Expand the new parent if collapsed
            collapsedIds.remove(newParid)
            rebuildDisplayList()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Outdent (become sibling of parent)

    @MainActor
    func outdentBlock(navId: String) async {
        guard let index = displayList.firstIndex(where: { $0.id == navId }) else { return }
        let node = displayList[index]
        guard let currentParid = node.parid else { return }

        // Find the parent node
        guard let parentNav = navList.first(where: { $0.id == currentParid }) else { return }
        guard let grandparentId = parentNav.parid else { return }

        // Don't outdent beyond root
        if grandparentId == OutlineTreeBuilder.nilUUID || grandparentId == rootNavId {
            // Moving to top level under root
            let newParid = rootNavId ?? grandparentId

            let parentOrder = parentNav.sameDeepOrder ?? 0
            // Find next sibling of parent
            let parentIndex = displayList.firstIndex(where: { $0.id == currentParid })
            let nextParentSibling: OutlineNode?
            if let pi = parentIndex {
                nextParentSibling = OutlineTreeBuilder.findNextSibling(in: displayList, at: pi)
            } else {
                nextParentSibling = nil
            }
            let newOrder = OutlineTreeBuilder.orderBetween(
                prev: parentOrder,
                next: nextParentSibling?.order
            )

            do {
                _ = try await navService.updateNavParent(
                    noteId: noteId, navId: navId, newParid: newParid, order: newOrder
                )
                navList = navList.map { nav in
                    if nav.id == navId {
                        return NavInfo(
                            id: nav.id, parid: newParid, sameDeepOrder: newOrder,
                            content: nav.content, accountId: nav.accountId, lastAccountId: nav.lastAccountId,
                            noteId: nav.noteId, hulunoteNote: nav.hulunoteNote, databaseId: nav.databaseId,
                            isDisplay: nav.isDisplay, isPublic: nav.isPublic, isDelete: nav.isDelete,
                            properties: nav.properties, createdAt: nav.createdAt, updatedAt: nav.updatedAt
                        )
                    }
                    return nav
                }
                rebuildDisplayList()
            } catch {
                self.error = error.localizedDescription
            }
        } else {
            // Normal outdent: become sibling of parent under grandparent
            let parentOrder = parentNav.sameDeepOrder ?? 0
            let parentIndex = displayList.firstIndex(where: { $0.id == currentParid })
            let nextParentSibling: OutlineNode?
            if let pi = parentIndex {
                nextParentSibling = OutlineTreeBuilder.findNextSibling(in: displayList, at: pi)
            } else {
                nextParentSibling = nil
            }
            let newOrder = OutlineTreeBuilder.orderBetween(
                prev: parentOrder,
                next: nextParentSibling?.order
            )

            do {
                _ = try await navService.updateNavParent(
                    noteId: noteId, navId: navId, newParid: grandparentId, order: newOrder
                )
                navList = navList.map { nav in
                    if nav.id == navId {
                        return NavInfo(
                            id: nav.id, parid: grandparentId, sameDeepOrder: newOrder,
                            content: nav.content, accountId: nav.accountId, lastAccountId: nav.lastAccountId,
                            noteId: nav.noteId, hulunoteNote: nav.hulunoteNote, databaseId: nav.databaseId,
                            isDisplay: nav.isDisplay, isPublic: nav.isPublic, isDelete: nav.isDelete,
                            properties: nav.properties, createdAt: nav.createdAt, updatedAt: nav.updatedAt
                        )
                    }
                    return nav
                }
                rebuildDisplayList()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Collapse/Expand

    func toggleCollapse(navId: String) {
        if collapsedIds.contains(navId) {
            collapsedIds.remove(navId)
        } else {
            collapsedIds.insert(navId)
        }
        rebuildDisplayList()
    }

    func clearFocusRequest() {
        focusNodeId = nil
    }

    // MARK: - Export

    func generateMarkdown() -> String {
        let allNodes = OutlineTreeBuilder.buildDisplayList(
            navList: navList,
            rootNavId: rootNavId,
            collapsedIds: []
        )

        var lines: [String] = ["# \(noteTitle)", ""]
        for node in allNodes {
            let indent = String(repeating: "  ", count: node.depth)
            lines.append("\(indent)- \(node.content)")
        }
        return lines.joined(separator: "\n")
    }

    func copyAsMarkdown() {
        UIPasteboard.general.string = generateMarkdown()
    }

    func copyAsChatGPT() {
        let markdown = generateMarkdown()
        let prompt = "Please convert the following Markdown content into ChatGPT's English conversation training:\n\(markdown)"
        UIPasteboard.general.string = prompt
    }

    // MARK: - Import Markdown

    @MainActor
    func importMarkdown(text: String) async {
        guard let rootId = rootNavId else { return }

        let lines = text.components(separatedBy: "\n")
        var parsedLines: [(depth: Int, content: String)] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Heading: # ## ### etc.
            if trimmed.hasPrefix("#") {
                let hashCount = trimmed.prefix(while: { $0 == "#" }).count
                let content = String(trimmed.dropFirst(hashCount)).trimmingCharacters(in: .whitespaces)
                if !content.isEmpty {
                    parsedLines.append((depth: max(0, hashCount - 1), content: content))
                }
                continue
            }

            // List item: "  - content" or "  * content"
            let leadingSpaces = line.prefix(while: { $0 == " " }).count
            if trimmed.hasPrefix("- ") {
                parsedLines.append((depth: leadingSpaces / 2, content: String(trimmed.dropFirst(2))))
                continue
            }
            if trimmed.hasPrefix("* ") {
                parsedLines.append((depth: leadingSpaces / 2, content: String(trimmed.dropFirst(2))))
                continue
            }

            // Plain text
            parsedLines.append((depth: 0, content: trimmed))
        }

        guard !parsedLines.isEmpty else { return }

        // Track parent ID at each depth level
        var parentAtDepth: [Int: String] = [0: rootId]
        var orderAtParent: [String: Float] = [:]

        // Start after existing top-level blocks
        let existingTopLevel = navList.filter { $0.parid == rootId && $0.isDelete != true }
        let maxOrder = existingTopLevel.map { $0.sameDeepOrder ?? 0 }.max() ?? 0
        orderAtParent[rootId] = maxOrder

        for (depth, content) in parsedLines {
            let parid = parentAtDepth[depth] ?? rootId
            let currentOrder = (orderAtParent[parid] ?? 0) + 100
            orderAtParent[parid] = currentOrder

            do {
                let response = try await navService.createNav(
                    noteId: noteId,
                    parid: parid,
                    content: content,
                    order: currentOrder
                )
                if let nav = response.nav {
                    navList.append(nav)
                    // This block becomes potential parent for deeper blocks
                    parentAtDepth[depth + 1] = nav.id
                    // Clear deeper parent references
                    for d in (depth + 2)...10 {
                        parentAtDepth.removeValue(forKey: d)
                    }
                }
            } catch {
                self.error = error.localizedDescription
                break
            }
        }

        rebuildDisplayList()
    }
}
