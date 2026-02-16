import Foundation

struct OutlineNode: Identifiable, Equatable {
    let id: String
    let parid: String?
    let content: String
    let order: Float
    let isDisplay: Bool
    let depth: Int
    let hasChildren: Bool
    let isCollapsed: Bool
}
