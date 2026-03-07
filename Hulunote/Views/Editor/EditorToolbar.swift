import SwiftUI

struct EditorKeyboardToolbar: View {
    let onIndent: () -> Void
    let onOutdent: () -> Void
    let onAddBlock: () -> Void
    let onDeleteBlock: () -> Void
    var onInsertLink: (() -> Void)? = nil
    var onOCRFromLibrary: (() -> Void)? = nil
    var onOCRFromCamera: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onOutdent) {
                Image(systemName: "decrease.indent")
                    .font(.system(size: 16))
                    .foregroundColor(.hulunoteAccent)
            }

            Button(action: onIndent) {
                Image(systemName: "increase.indent")
                    .font(.system(size: 16))
                    .foregroundColor(.hulunoteAccent)
            }

            Divider()
                .frame(height: 20)

            Button(action: onAddBlock) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.hulunoteAccent)
            }

            Button(action: onDeleteBlock) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.hulunoteTextSecondary)
            }

            Divider()
                .frame(height: 20)

            Button {
                onInsertLink?()
            } label: {
                Text("[]")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.hulunoteAccent)
            }

            Divider()
                .frame(height: 20)

            Button {
                onOCRFromLibrary?()
            } label: {
                Image(systemName: "photo")
                    .font(.system(size: 16))
                    .foregroundColor(.hulunoteAccent)
            }

            Button {
                onOCRFromCamera?()
            } label: {
                Image(systemName: "camera")
                    .font(.system(size: 16))
                    .foregroundColor(.hulunoteAccent)
            }

            Spacer()

            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 16))
                    .foregroundColor(.hulunoteTextSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.hulunoteSidebar)
    }
}
