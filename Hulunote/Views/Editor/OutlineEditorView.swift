import SwiftUI

struct OutlineEditorView: View {
    @Environment(AppViewModel.self) private var appViewModel
    let noteId: String
    let noteTitle: String
    let rootNavId: String?

    @State private var viewModel: OutlineEditorViewModel?
    @State private var selectedNodeId: String?

    var body: some View {
        ZStack {
            Color.hulunoteBackground.ignoresSafeArea()

            if let vm = viewModel {
                if vm.isLoading && vm.displayList.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.hulunoteAccent)
                        Text("Loading outline...")
                            .font(HulunoteFont.small)
                            .foregroundColor(.hulunoteTextSecondary)
                    }
                } else if let error = vm.error, vm.displayList.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.hulunoteTextSecondary)
                        Text(error)
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextSecondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await vm.loadNavs() }
                        }
                        .foregroundColor(.hulunoteAccent)
                    }
                    .padding()
                } else if vm.displayList.isEmpty {
                    // Empty note
                    VStack(spacing: 16) {
                        Image(systemName: "text.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.hulunoteTextSecondary)
                        Text("Empty outline")
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextSecondary)
                        Button {
                            Task { await vm.createFirstBlock() }
                        } label: {
                            Text("Add first block")
                                .font(HulunoteFont.bodyMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(LinearGradient.hulunotePurple)
                                .cornerRadius(20)
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 2) {
                                ForEach(vm.displayList) { node in
                                    OutlineBlockView(
                                        node: node,
                                        onContentChange: { content in
                                            vm.onContentChange(navId: node.id, content: content)
                                        },
                                        onEnterKey: {
                                            selectedNodeId = node.id
                                            Task { await vm.createNewBlock(afterNodeId: node.id) }
                                        },
                                        onBackspaceEmpty: {
                                            if node.content.isEmpty {
                                                Task { await vm.deleteBlock(navId: node.id) }
                                            }
                                        },
                                        onToggleCollapse: {
                                            vm.toggleCollapse(navId: node.id)
                                        }
                                    )
                                    .id(node.id)
                                    .onTapGesture {
                                        selectedNodeId = node.id
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                            .padding(.bottom, 100)
                        }

                        // Keyboard toolbar
                        EditorKeyboardToolbar(
                            onIndent: {
                                if let id = selectedNodeId {
                                    Task { await vm.indentBlock(navId: id) }
                                }
                            },
                            onOutdent: {
                                if let id = selectedNodeId {
                                    Task { await vm.outdentBlock(navId: id) }
                                }
                            },
                            onAddBlock: {
                                if let id = selectedNodeId {
                                    Task { await vm.createNewBlock(afterNodeId: id) }
                                } else if let lastNode = vm.displayList.last {
                                    Task { await vm.createNewBlock(afterNodeId: lastNode.id) }
                                } else {
                                    Task { await vm.createFirstBlock() }
                                }
                            },
                            onDeleteBlock: {
                                if let id = selectedNodeId {
                                    Task { await vm.deleteBlock(navId: id) }
                                    selectedNodeId = nil
                                }
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle(noteTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let vm = viewModel {
                        Button {
                            Task { await vm.loadNavs() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }

                        if let id = selectedNodeId {
                            Divider()

                            Button {
                                Task { await vm.indentBlock(navId: id) }
                            } label: {
                                Label("Indent", systemImage: "increase.indent")
                            }

                            Button {
                                Task { await vm.outdentBlock(navId: id) }
                            } label: {
                                Label("Outdent", systemImage: "decrease.indent")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.hulunoteAccent)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = OutlineEditorViewModel(
                    noteId: noteId,
                    noteTitle: noteTitle,
                    rootNavId: rootNavId,
                    apiClient: appViewModel.apiClient
                )
            }
        }
        .task {
            await viewModel?.loadNavs()
        }
    }
}
