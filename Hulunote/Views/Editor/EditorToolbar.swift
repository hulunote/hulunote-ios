import SwiftUI

struct EditorKeyboardToolbar: View {
    let onIndent: () -> Void
    let onOutdent: () -> Void
    let onAddBlock: () -> Void
    let onDeleteBlock: () -> Void

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
