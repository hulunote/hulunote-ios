import SwiftUI

struct NoteTTSView: View {
    @Environment(AppViewModel.self) private var appViewModel
    let noteId: String
    let noteTitle: String
    let rootNavId: String?

    @State private var viewModel: NoteTTSViewModel?

    var body: some View {
        ZStack {
            Color.hulunoteBackground.ignoresSafeArea()

            if let vm = viewModel {
                if vm.isLoading {
                    ProgressView()
                        .tint(.hulunoteAccent)
                } else if let error = vm.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.hulunoteTextSecondary)
                        Text(error)
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if vm.paragraphs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "text.page")
                            .font(.system(size: 40))
                            .foregroundColor(.hulunoteTextSecondary)
                        Text("No content to read")
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextSecondary)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Karaoke text area
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    ForEach(
                                        Array(vm.paragraphs.enumerated()),
                                        id: \.offset
                                    ) { index, paragraph in
                                        paragraphView(vm: vm, index: index, text: paragraph)
                                            .id(index)
                                            .padding(.horizontal, 24)
                                    }
                                }
                                .padding(.vertical, 32)
                            }
                            .onChange(of: vm.currentParagraphIndex) { _, newIndex in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(max(0, newIndex), anchor: .center)
                                }
                            }
                        }

                        Divider()
                            .background(Color.hulunoteBorder)

                        // Playback controls
                        controlBar(vm: vm)
                    }
                }
            }
        }
        .navigationTitle(noteTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = NoteTTSViewModel(
                    noteId: noteId,
                    noteTitle: noteTitle,
                    rootNavId: rootNavId,
                    apiClient: appViewModel.apiClient
                )
            }
        }
        .task {
            await viewModel?.loadContent()
        }
        .onDisappear {
            viewModel?.stop()
        }
    }

    // MARK: - Paragraph View

    @ViewBuilder
    private func paragraphView(vm: NoteTTSViewModel, index: Int, text: String) -> some View {
        if index < vm.currentParagraphIndex {
            // Already spoken
            Text(text)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.hulunoteAccent.opacity(0.5))
                .lineSpacing(6)
        } else if index == vm.currentParagraphIndex {
            // Currently speaking - karaoke highlight
            karaokeText(
                text: text,
                wordLocation: vm.currentWordLocation,
                wordLength: vm.currentWordLength
            )
            .lineSpacing(6)
        } else {
            // Not yet spoken
            Text(text)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.hulunoteTextMuted.opacity(0.6))
                .lineSpacing(6)
        }
    }

    private func karaokeText(text: String, wordLocation: Int, wordLength: Int) -> Text {
        let nsText = text as NSString
        let totalLength = nsText.length

        let safeLocation = min(wordLocation, totalLength)
        let safeLength = min(wordLength, totalLength - safeLocation)

        let before = safeLocation > 0
            ? nsText.substring(to: safeLocation) : ""
        let current = safeLength > 0
            ? nsText.substring(with: NSRange(location: safeLocation, length: safeLength)) : ""
        let afterStart = safeLocation + safeLength
        let after = afterStart < totalLength
            ? nsText.substring(from: afterStart) : ""

        return Text(before)
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.hulunoteAccent)
            + Text(current)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(Color(hex: "FFD700"))
            + Text(after)
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.hulunoteTextMuted.opacity(0.6))
    }

    // MARK: - Control Bar

    private func controlBar(vm: NoteTTSViewModel) -> some View {
        HStack(spacing: 44) {
            Button {
                vm.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.hulunoteTextSecondary)
            }

            Button {
                vm.togglePlayPause()
            } label: {
                Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.hulunoteAccent)
            }

            // Speed indicator (placeholder for symmetry)
            Text("0.9x")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.hulunoteTextMuted)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.hulunoteCard)
    }
}
