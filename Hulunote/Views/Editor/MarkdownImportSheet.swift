import SwiftUI
import UIKit

struct MarkdownImportSheet: View {
    @State private var markdownText = ""
    let onConfirm: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextEditor(text: $markdownText)
                    .font(HulunoteFont.body)
                    .foregroundColor(.hulunoteTextPrimary)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.hulunoteBackground)
            }
            .navigationTitle("Import Markdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if let clip = UIPasteboard.general.string {
                            markdownText = clip
                        }
                    } label: {
                        Label("Paste", systemImage: "doc.on.clipboard")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        onConfirm(markdownText)
                        dismiss()
                    }
                    .disabled(markdownText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
