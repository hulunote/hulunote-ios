import SwiftUI

struct OutlineBlockView: View {
    let node: OutlineNode
    let onContentChange: (String) -> Void
    let onEnterKey: () -> Void
    let onBackspaceEmpty: () -> Void
    let onToggleCollapse: () -> Void
    let onLinkTap: (String) -> Void

    @State private var text: String
    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    init(
        node: OutlineNode,
        onContentChange: @escaping (String) -> Void,
        onEnterKey: @escaping () -> Void,
        onBackspaceEmpty: @escaping () -> Void,
        onToggleCollapse: @escaping () -> Void,
        onLinkTap: @escaping (String) -> Void = { _ in }
    ) {
        self.node = node
        self.onContentChange = onContentChange
        self.onEnterKey = onEnterKey
        self.onBackspaceEmpty = onBackspaceEmpty
        self.onToggleCollapse = onToggleCollapse
        self.onLinkTap = onLinkTap
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

            // Content: display mode (with links) or edit mode (TextField)
            if isEditing {
                TextField("", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(HulunoteFont.body)
                    .foregroundColor(.hulunoteTextPrimary)
                    .focused($isFocused)
                    .onSubmit {
                        onEnterKey()
                    }
                    .onChange(of: text) { oldValue, newValue in
                        if oldValue != newValue {
                            onContentChange(newValue)
                        }
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused {
                            isEditing = false
                        }
                    }
            } else {
                // Display mode: render [[links]] as tappable
                if BiDirectionalLinkParser.containsLinks(text) {
                    Text(BiDirectionalLinkParser.parseToAttributedString(text))
                        .font(HulunoteFont.body)
                        .foregroundColor(.hulunoteTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .environment(\.openURL, OpenURLAction { url in
                            if url.scheme == "hulunote",
                               url.host == "note",
                               let title = url.pathComponents.dropFirst().first?.removingPercentEncoding {
                                onLinkTap(title)
                                return .handled
                            }
                            return .systemAction
                        })
                        .onTapGesture {
                            isEditing = true
                            isFocused = true
                        }
                } else {
                    // No links - plain text, tap to edit
                    Text(text.isEmpty ? " " : text)
                        .font(HulunoteFont.body)
                        .foregroundColor(text.isEmpty ? .hulunoteTextMuted : .hulunoteTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isEditing = true
                            isFocused = true
                        }
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
