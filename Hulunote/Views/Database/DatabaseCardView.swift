import SwiftUI

struct DatabaseCardView: View {
    let database: DatabaseInfo
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.hulunotePurpleStart)

                    Spacer()

                    if database.isDefault == true {
                        Text("Default")
                            .font(HulunoteFont.caption)
                            .foregroundColor(.hulunotePurpleStart)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.hulunoteTag)
                            .cornerRadius(10)
                    }
                }

                Text(database.name)
                    .font(HulunoteFont.cardTitle)
                    .foregroundColor(.hulunoteTextPrimary)
                    .lineLimit(2)

                if let desc = database.description, !desc.isEmpty {
                    Text(desc)
                        .font(HulunoteFont.small)
                        .foregroundColor(.hulunoteTextSecondary)
                        .lineLimit(2)
                }

                if let date = database.createdAt {
                    Text(formatDate(date))
                        .font(HulunoteFont.caption)
                        .foregroundColor(.hulunoteTextMuted)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.hulunoteCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.hulunoteBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateStyle = .medium
            return display.string(from: date)
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateStyle = .medium
            return display.string(from: date)
        }
        return dateString
    }
}
