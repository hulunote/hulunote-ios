import SwiftUI

struct CreateNoteSheet: View {
    @Binding var title: String
    let isCreating: Bool
    let onCreate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hulunoteBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note Title")
                            .font(HulunoteFont.smallMedium)
                            .foregroundColor(.hulunoteTextSecondary)

                        TextField("Enter note title", text: $title)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.hulunoteInputBackground)
                            .cornerRadius(10)
                            .foregroundColor(.hulunoteTextPrimary)
                    }

                    Button {
                        onCreate()
                    } label: {
                        ZStack {
                            LinearGradient.hulunotePurple
                                .frame(height: 44)
                                .cornerRadius(22)

                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Note")
                                    .font(HulunoteFont.bodyMedium)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                        .foregroundColor(.hulunoteAccent)
                }
            }
        }
    }
}
