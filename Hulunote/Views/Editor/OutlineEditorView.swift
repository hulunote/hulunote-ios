import SwiftUI
import UIKit

struct OutlineEditorView: View {
    @Environment(AppViewModel.self) private var appViewModel
    let noteId: String
    let noteTitle: String
    let rootNavId: String?
    let databaseId: String?
    @Binding var path: NavigationPath

    @State private var viewModel: OutlineEditorViewModel?
    @State private var selectedNodeId: String?
    @State private var backlinksViewModel: BacklinksViewModel?
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var isOCRProcessing = false
    @State private var showOCRPreview = false
    @State private var ocrLines: [String] = []

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
                                        },
                                        onLinkTap: { title in
                                            navigateToNote(title: title)
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

                            // Backlinks section
                            if let blvm = backlinksViewModel {
                                BacklinksView(
                                    backlinks: blvm.backlinks,
                                    isLoading: blvm.isLoading,
                                    onNoteTap: { noteId, noteTitle, rootNavId in
                                        path.append(EditorRoute(
                                            noteId: noteId,
                                            noteTitle: noteTitle,
                                            rootNavId: rootNavId,
                                            databaseId: databaseId
                                        ))
                                    }
                                )
                            }

                            Spacer().frame(height: 100)
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
                            },
                            onOCRFromLibrary: {
                                imagePickerSource = .photoLibrary
                                showImagePicker = true
                            },
                            onOCRFromCamera: {
                                imagePickerSource = .camera
                                showImagePicker = true
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
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(sourceType: imagePickerSource) { image in
                handleOCRImage(image)
            }
        }
        .sheet(isPresented: $showOCRPreview) {
            OCRPreviewSheet(lines: $ocrLines) { confirmedLines in
                importOCRLines(confirmedLines)
            }
        }
        .overlay {
            if isOCRProcessing {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                        Text("Recognizing text...")
                            .font(HulunoteFont.small)
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
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
            if backlinksViewModel == nil, let dbId = databaseId {
                backlinksViewModel = BacklinksViewModel(
                    noteTitle: noteTitle,
                    noteId: noteId,
                    databaseId: dbId,
                    apiClient: appViewModel.apiClient
                )
            }
        }
        .task {
            await viewModel?.loadNavs()
            await backlinksViewModel?.loadBacklinks()
        }
    }

    private func handleOCRImage(_ image: UIImage) {
        isOCRProcessing = true
        Task {
            let recognizedText = await OCRService.recognizeText(from: image)
            await MainActor.run {
                isOCRProcessing = false
                guard !recognizedText.isEmpty else { return }
                ocrLines = recognizedText.components(separatedBy: "\n")
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                if !ocrLines.isEmpty {
                    showOCRPreview = true
                }
            }
        }
    }

    private func importOCRLines(_ lines: [String]) {
        guard let vm = viewModel else { return }
        Task {
            for line in lines {
                if let lastNode = vm.displayList.last {
                    await vm.createNewBlock(afterNodeId: lastNode.id)
                } else {
                    await vm.createFirstBlock()
                }
                if let newNodeId = vm.focusNodeId {
                    vm.onContentChange(navId: newNodeId, content: line)
                }
            }
        }
    }

    private func navigateToNote(title: String) {
        guard let dbId = databaseId else { return }

        Task {
            let noteService = NoteService(api: appViewModel.apiClient)
            do {
                let allNotes = try await noteService.getAllNotes(databaseId: dbId)
                if let targetNote = allNotes.first(where: {
                    $0.title == title && $0.isDelete != true
                }) {
                    await MainActor.run {
                        path.append(EditorRoute(
                            noteId: targetNote.id,
                            noteTitle: targetNote.title,
                            rootNavId: targetNote.rootNavId,
                            databaseId: dbId
                        ))
                    }
                }
            } catch {
                // Note not found - do nothing
            }
        }
    }
}
