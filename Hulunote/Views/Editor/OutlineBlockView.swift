import SwiftUI

struct OutlineBlockView: View {
    let node: OutlineNode
    let onContentChange: (String) -> Void
    let onEnterKey: () -> Void
    let onBackspaceEmpty: () -> Void
    let onToggleCollapse: () -> Void

    @State private var text: String

    init(
        node: OutlineNode,
        onContentChange: @escaping (String) -> Void,
        onEnterKey: @escaping () -> Void,
        onBackspaceEmpty: @escaping () -> Void,
        onToggleCollapse: @escaping () -> Void
    ) {
        self.node = node
        self.onContentChange = onContentChange
        self.onEnterKey = onEnterKey
        self.onBackspaceEmpty = onBackspaceEmpty
        self.onToggleCollapse = onToggleCollapse
        self._text = State(initialValue: node.content)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Collapse/expand toggle area
            if node.hasChildren {
                Button(action: onToggleCollapse) {
                    Image(systemName: node.isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.hulunoteTextSecondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            } else {
                Color.clear.frame(width: 22, height: 22)
            }

            // Bullet point
            Circle()
                .fill(Color.hulunoteTextSecondary.opacity(0.6))
                .frame(width: 6, height: 6)
                .padding(.top, 10)
                .padding(.trailing, 6)

            // Editable text
            TextField("", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(HulunoteFont.body)
                .foregroundColor(.hulunoteTextPrimary)
                .onSubmit {
                    onEnterKey()
                }
                .onChange(of: text) { oldValue, newValue in
                    if oldValue != newValue {
                        onContentChange(newValue)
                    }
                }
        }
        .padding(.leading, CGFloat(node.depth * 24))
        .padding(.trailing, 8)
        .padding(.vertical, 1)
        .contentShape(Rectangle())
        .onChange(of: node.content) { _, newContent in
            if text != newContent {
                text = newContent
            }
        }
    }
}
