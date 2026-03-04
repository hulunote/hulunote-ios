import SwiftUI

struct R2D2MessageBubble: View {
    let message: R2D2Message
    let onReply: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Spacer(minLength: 60)

            VStack(alignment: .trailing, spacing: 4) {
                // Reply quote
                if let replyContent = message.replyToContent {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.hulunoteAccent.opacity(0.6))
                            .frame(width: 3)

                        Text(replyContent)
                            .font(HulunoteFont.caption)
                            .foregroundColor(.hulunoteTextSecondary)
                            .lineLimit(2)

                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }

                // Message content
                HStack {
                    Text(message.content)
                        .font(HulunoteFont.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }

                // Timestamp
                if let dateStr = message.createdAt {
                    Text(formatTime(dateStr))
                        .font(HulunoteFont.small)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                ChatBubbleShape()
                    .fill(Color.hulunoteAccent.opacity(0.85))
            )
            .contextMenu {
                Button {
                    onReply()
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateFormat = "HH:mm"
            return display.string(from: date)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateFormat = "HH:mm"
            return display.string(from: date)
        }
        return ""
    }
}

// MARK: - Chat Bubble Shape (WeChat-style with tail on right)

struct ChatBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailRadius: CGFloat = 4

        var path = Path()
        // Top-left corner
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        // Top-right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
            radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false
        )
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tailRadius))
        // Bottom-right corner (small tail)
        path.addArc(
            center: CGPoint(x: rect.maxX - tailRadius, y: rect.maxY - tailRadius),
            radius: tailRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false
        )
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
            radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
        )
        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        // Top-left corner
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
            radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
        )

        return path
    }
}
