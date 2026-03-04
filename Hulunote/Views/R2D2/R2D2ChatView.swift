import SwiftUI

struct R2D2ChatView: View {
    @Environment(AppViewModel.self) private var appViewModel
    let noteId: String
    let noteTitle: String
    let rootNavId: String?
    @State private var viewModel: R2D2ChatViewModel?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            Color.hulunoteBackground.ignoresSafeArea()

            if let vm = viewModel {
                VStack(spacing: 0) {
                    // Messages list
                    messagesList(vm: vm)

                    // Recording status bar
                    if vm.speechService.isRecording {
                        recordingBar(vm: vm)
                    }

                    // Reply preview bar
                    if let reply = vm.replyingTo {
                        replyPreview(reply: reply, vm: vm)
                    }

                    // Input bar
                    inputBar(vm: vm)
                }
            }
        }
        .navigationTitle(noteTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = R2D2ChatViewModel(
                    noteId: noteId,
                    noteTitle: noteTitle,
                    rootNavId: rootNavId,
                    apiClient: appViewModel.apiClient
                )
            }
        }
        .task {
            await viewModel?.loadMessages()
        }
    }

    // MARK: - Messages List

    @ViewBuilder
    private func messagesList(vm: R2D2ChatViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                if vm.isLoading && vm.messages.isEmpty {
                    ProgressView()
                        .tint(.hulunoteAccent)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if vm.messages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(.hulunoteTextSecondary)
                        Text("No messages yet")
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextSecondary)
                        Text("Start typing to add notes")
                            .font(HulunoteFont.small)
                            .foregroundColor(.hulunoteTextMuted)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.messages) { message in
                            R2D2MessageBubble(
                                message: message,
                                onReply: {
                                    vm.startReply(to: message)
                                    isInputFocused = true
                                },
                                onDelete: {
                                    Task { await vm.deleteMessage(messageId: message.id) }
                                }
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .onChange(of: vm.messages.count) {
                if let lastId = vm.messages.last?.id {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Reply Preview

    @ViewBuilder
    private func replyPreview(reply: R2D2Message, vm: R2D2ChatViewModel) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.hulunoteAccent)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text("Replying")
                    .font(HulunoteFont.caption)
                    .foregroundColor(.hulunoteAccent)
                Text(reply.content)
                    .font(HulunoteFont.caption)
                    .foregroundColor(.hulunoteTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                vm.cancelReply()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.hulunoteTextSecondary)
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.hulunoteSidebar)
    }

    // MARK: - Recording Bar

    @ViewBuilder
    private func recordingBar(vm: R2D2ChatViewModel) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .modifier(PulseModifier())

            Text("\(vm.speechService.recordingTimeRemaining)s")
                .font(HulunoteFont.caption)
                .foregroundColor(.red)
                .monospacedDigit()

            Text(vm.speechService.recognizedText.isEmpty
                 ? "Listening..."
                 : vm.speechService.recognizedText)
                .font(HulunoteFont.caption)
                .foregroundColor(.hulunoteTextSecondary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.hulunoteSidebar)
    }

    // MARK: - Input Bar

    @ViewBuilder
    private func inputBar(vm: R2D2ChatViewModel) -> some View {
        HStack(spacing: 10) {
            // Mic button
            Button {
                vm.toggleRecording()
            } label: {
                Image(systemName: vm.speechService.isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 22))
                    .foregroundColor(vm.speechService.isRecording ? .red : .hulunoteTextSecondary)
            }

            TextField("Type a message...", text: Binding(
                get: { vm.inputText },
                set: { vm.inputText = $0 }
            ), axis: .vertical)
            .lineLimit(1...5)
            .font(HulunoteFont.body)
            .foregroundColor(.hulunoteTextPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.hulunoteInputBackground)
            .cornerRadius(20)
            .focused($isInputFocused)

            Button {
                Task { await vm.sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(
                        vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .hulunoteTextMuted
                            : .hulunoteAccent
                    )
            }
            .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.hulunoteSidebar)
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
