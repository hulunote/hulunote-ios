import SwiftUI

struct NoteCardView: View {
    let note: NoteInfo
    let onTap: () -> Void
    let onDelete: () -> Void
    let onToggleShortcut: () -> Void
    var onR2D2: (() -> Void)? = nil

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Note icon
                Image(systemName: "doc.text")
                    .font(.system(size: 18))
                    .foregroundColor(.hulunotePurpleStart)
                    .frame(width: 32)

                // Title and metadata
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(note.title)
                            .font(HulunoteFont.bodyMedium)
                            .foregroundColor(.hulunoteTextPrimary)
                            .lineLimit(1)

                        if note.isShortcut == true {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                        }
                    }

                    if let date = note.updatedAt ?? note.createdAt {
                        Text(formatDate(date))
                            .font(HulunoteFont.caption)
                            .foregroundColor(.hulunoteTextMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.hulunoteTextMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.hulunoteCard)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onToggleShortcut()
            } label: {
                Label(
                    note.isShortcut == true ? "Remove from Shortcuts" : "Add to Shortcuts",
                    systemImage: note.isShortcut == true ? "star.slash" : "star"
                )
            }

            if let onR2D2 {
                Button {
                    onR2D2()
                } label: {
                    Label("R2D2 Chat", systemImage: "bubble.left.and.bubble.right")
                }
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateStyle = .medium
            display.timeStyle = .short
            return display.string(from: date)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateStyle = .medium
            display.timeStyle = .short
            return display.string(from: date)
        }
        return dateString
    }
}
