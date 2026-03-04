import SwiftUI

struct NoteListView: View {
    @Environment(AppViewModel.self) private var appViewModel
    let databaseId: String
    let databaseName: String
    @Binding var path: NavigationPath
    @State private var viewModel: NoteListViewModel?

    var body: some View {
        ZStack {
            Color.hulunoteBackground.ignoresSafeArea()

            if let vm = viewModel {
                if vm.isLoading && vm.notes.isEmpty {
                    ProgressView()
                        .tint(.hulunoteAccent)
                } else if let error = vm.error, vm.notes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.hulunoteTextSecondary)
                        Text(error)
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextSecondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await vm.loadNotes() }
                        }
                        .foregroundColor(.hulunoteAccent)
                    }
                    .padding()
                } else if vm.filteredNotes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(.hulunoteTextSecondary)
                        Text(vm.searchText.isEmpty ? "No notes yet" : "No matching notes")
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextSecondary)
                        if vm.searchText.isEmpty {
                            Text("Tap + to create your first note")
                                .font(HulunoteFont.small)
                                .foregroundColor(.hulunoteTextMuted)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(vm.filteredNotes) { note in
                                NoteCardView(
                                    note: note,
                                    onTap: {
                                        path.append(EditorRoute(
                                            noteId: note.id,
                                            noteTitle: note.title,
                                            rootNavId: note.rootNavId
                                        ))
                                    },
                                    onDelete: {
                                        Task { await vm.deleteNote(noteId: note.id) }
                                    },
                                    onToggleShortcut: {
                                        Task { await vm.toggleShortcut(noteId: note.id) }
                                    },
                                    onR2D2: {
                                        path.append(R2D2Route(
                                            noteId: note.id,
                                            noteTitle: note.title,
                                            rootNavId: note.rootNavId
                                        ))
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .refreshable {
                        await vm.loadNotes()
                    }
                }
            }
        }
        .navigationTitle(databaseName)
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ),
            prompt: "Search notes"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        path.append(WordLearningRoute(
                            databaseId: databaseId,
                            databaseName: databaseName
                        ))
                    } label: {
                        Image(systemName: "textformat.abc")
                            .foregroundColor(.hulunoteAccent)
                    }
                    Button {
                        viewModel?.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.hulunoteAccent)
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showCreateSheet ?? false },
            set: { viewModel?.showCreateSheet = $0 }
        )) {
            if let vm = viewModel {
                CreateNoteSheet(
                    title: Binding(
                        get: { vm.newNoteTitle },
                        set: { vm.newNoteTitle = $0 }
                    ),
                    isCreating: vm.isCreating,
                    onCreate: { Task { await vm.createNote() } },
                    onCancel: { vm.showCreateSheet = false }
                )
                .presentationDetents([.medium])
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = NoteListViewModel(
                    databaseId: databaseId,
                    apiClient: appViewModel.apiClient
                )
            }
        }
        .task {
            await viewModel?.loadNotes()
        }
    }
}
