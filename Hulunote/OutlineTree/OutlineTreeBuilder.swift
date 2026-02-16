import Foundation

enum OutlineTreeBuilder {
    static let nilUUID = "00000000-0000-0000-0000-000000000000"

    /// Build a flat display list from NavInfo array via DFS.
    /// Each OutlineNode carries its depth for indentation rendering.
    static func buildDisplayList(
        navList: [NavInfo],
        rootNavId: String?,
        collapsedIds: Set<String>
    ) -> [OutlineNode] {
        guard !navList.isEmpty else { return [] }

        // Build parent -> children map, filtering out deleted navs
        var childrenMap: [String: [NavInfo]] = [:]
        for nav in navList {
            guard nav.isDelete != true else { continue }
            let parentId = nav.parid ?? ""
            childrenMap[parentId, default: []].append(nav)
        }

        // Sort children by same-deep-order at each level
        for key in childrenMap.keys {
            childrenMap[key]?.sort { ($0.sameDeepOrder ?? 0) < ($1.sameDeepOrder ?? 0) }
        }

        var result: [OutlineNode] = []
        let rootId = rootNavId ?? ""

        func dfs(parentId: String, depth: Int) {
            guard let children = childrenMap[parentId] else { return }
            for child in children {
                // Skip the root node itself from display
                let isRoot = child.parid == nil
                    || child.parid == nilUUID
                    || child.parid == child.id
                    || child.id == rootId

                if isRoot && child.content == "ROOT" {
                    // Recurse into root's children at same depth
                    dfs(parentId: child.id, depth: depth)
                    continue
                }

                let childChildren = childrenMap[child.id]
                let hasChildren = !(childChildren?.isEmpty ?? true)
                let isCollapsed = collapsedIds.contains(child.id)

                result.append(OutlineNode(
                    id: child.id,
                    parid: child.parid,
                    content: child.content,
                    order: child.sameDeepOrder ?? 0,
                    isDisplay: child.isDisplay ?? true,
                    depth: depth,
                    hasChildren: hasChildren,
                    isCollapsed: isCollapsed
                ))

                if hasChildren && !isCollapsed {
                    dfs(parentId: child.id, depth: depth + 1)
                }
            }
        }

        dfs(parentId: rootId, depth: 0)

        // If nothing found with rootId, try nilUUID as parent
        if result.isEmpty && rootId != nilUUID {
            dfs(parentId: nilUUID, depth: 0)
        }

        return result
    }

    /// Calculate an order value between two siblings for insertion.
    static func orderBetween(prev: Float?, next: Float?) -> Float {
        let p = prev ?? 0
        let n = next ?? (p + 200)
        return (p + n) / 2
    }

    /// Find the previous sibling of a node at a given index in the display list.
    static func findPreviousSibling(in displayList: [OutlineNode], at index: Int) -> OutlineNode? {
        guard index > 0 else { return nil }
        let current = displayList[index]
        for i in stride(from: index - 1, through: 0, by: -1) {
            let node = displayList[i]
            if node.parid == current.parid && node.depth == current.depth {
                return node
            }
            if node.depth < current.depth { break }
        }
        return nil
    }

    /// Find the next sibling of a node at a given index in the display list.
    static func findNextSibling(in displayList: [OutlineNode], at index: Int) -> OutlineNode? {
        guard index < displayList.count - 1 else { return nil }
        let current = displayList[index]
        for i in (index + 1)..<displayList.count {
            let node = displayList[i]
            if node.parid == current.parid && node.depth == current.depth {
                return node
            }
            if node.depth < current.depth { break }
        }
        return nil
    }

    /// Find the last descendant index of a node (for operations that need to know the full subtree).
    static func findLastDescendantIndex(in displayList: [OutlineNode], at index: Int) -> Int {
        let baseDepth = displayList[index].depth
        var lastIndex = index
        for i in (index + 1)..<displayList.count {
            if displayList[i].depth > baseDepth {
                lastIndex = i
            } else {
                break
            }
        }
        return lastIndex
    }
}
