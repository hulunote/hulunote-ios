import SwiftUI

struct BacklinksView: View {
    let backlinks: [BacklinkItem]
    let isLoading: Bool
    let onNoteTap: (String, String, String?) -> Void // noteId, noteTitle, rootNavId

    var body: some View {
        if isLoading || !backlinks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 12))
                        .foregroundColor(.hulunoteTextSecondary)
                    Text("Linked References")
                        .font(HulunoteFont.smallMedium)
                        .foregroundColor(.hulunoteTextSecondary)
                    if !backlinks.isEmpty {
                        Text("\(backlinks.count)")
                            .font(HulunoteFont.small)
                            .foregroundColor(.hulunoteAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.hulunoteAccent.opacity(0.15))
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                if isLoading {
                    HStack {
                        ProgressView()
                            .tint(.hulunoteAccent)
                            .scaleEffect(0.8)
                        Text("Searching backlinks...")
                            .font(HulunoteFont.small)
                            .foregroundColor(.hulunoteTextMuted)
                    }
                    .padding(.horizontal, 16)
                } else {
                    ForEach(backlinks) { item in
                        Button {
                            onNoteTap(item.noteId, item.noteTitle, item.rootNavId)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                // Note title
                                Text(item.noteTitle)
                                    .font(HulunoteFont.bodyMedium)
                                    .foregroundColor(.hulunoteAccent)

                                // Block content with link highlighted
                                Text(BiDirectionalLinkParser.parseToAttributedString(item.blockContent))
                                    .font(HulunoteFont.small)
                                    .foregroundColor(.hulunoteTextSecondary)
                                    .lineLimit(3)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.hulunoteCard)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }
}
