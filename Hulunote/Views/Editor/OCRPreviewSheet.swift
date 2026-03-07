import SwiftUI

struct OCRPreviewSheet: View {
    @Binding var lines: [String]
    let onConfirm: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(lines.indices, id: \.self) { index in
                        TextField("Line \(index + 1)", text: $lines[index], axis: .vertical)
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextPrimary)
                    }
                    .onDelete { indexSet in
                        lines.remove(atOffsets: indexSet)
                    }
                } header: {
                    Text("Tap to edit, swipe to delete")
                        .font(HulunoteFont.small)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("OCR Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        let nonEmpty = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                        onConfirm(nonEmpty)
                        dismiss()
                    }
                    .disabled(lines.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty })
                }
            }
        }
    }
}
