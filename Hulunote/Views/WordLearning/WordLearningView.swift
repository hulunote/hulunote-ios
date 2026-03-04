import SwiftUI
import UIKit

struct WordLearningView: View {
    @Environment(AppViewModel.self) private var appViewModel
    let databaseId: String
    let databaseName: String
    @State private var viewModel: WordLearningViewModel?

    var body: some View {
        ZStack {
            Color.hulunoteBackground.ignoresSafeArea()

            if let vm = viewModel {
                if vm.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.hulunoteAccent)
                        Text("Loading words from notes...")
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextSecondary)
                    }
                } else if let error = vm.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.hulunoteTextSecondary)
                        Text(error)
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextSecondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await vm.loadWords() }
                        }
                        .foregroundColor(.hulunoteAccent)
                    }
                    .padding()
                } else if vm.words.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "textformat.abc")
                            .font(.system(size: 40))
                            .foregroundColor(.hulunoteTextSecondary)
                        Text("No new words found")
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextSecondary)
                    }
                } else {
                    wordLearningContent(vm: vm)
                }
            }
        }
        .navigationTitle("Learn Words")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = WordLearningViewModel(
                    databaseId: databaseId,
                    databaseName: databaseName,
                    apiClient: appViewModel.apiClient
                )
            }
        }
        .task {
            await viewModel?.loadWords()
        }
    }

    @ViewBuilder
    private func wordLearningContent(vm: WordLearningViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Current word display
            Text(vm.currentWord.isEmpty ? "Tap Speak Next" : vm.currentWord)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.hulunoteTextPrimary)
                .padding()

            // Progress
            Text("\(vm.currentIndex) / \(vm.totalCount)")
                .font(HulunoteFont.caption)
                .foregroundColor(.hulunoteTextSecondary)

            Spacer()

            // Control buttons row 1
            HStack(spacing: 16) {
                controlButton(title: "Repeat", icon: "arrow.counterclockwise") {
                    vm.speakCurrent()
                }
                controlButton(title: "<<", icon: "backward.fill") {
                    vm.speakPrevious()
                }
                controlButton(title: "Fast", icon: "forward.fill") {
                    vm.speakAll()
                }
                controlButton(title: "Dict", icon: "book.fill") {
                    openDictionary(word: vm.currentWord)
                }
            }
            .padding(.horizontal)

            Button {
                Task { await vm.markAsRemembered() }
            } label: {
                HStack(spacing: 8) {
                    if vm.isSaving {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text("I've remembered")
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.hulunoteSuccess)
                )
            }
            .disabled(vm.isSaving || vm.currentWord.isEmpty)
            .padding(.horizontal, 32)

            // Primary button: Speak Next
            Button {
                vm.speakNext()
            } label: {
                Text("Speak Next")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.hulunoteAccent)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    @ViewBuilder
    private func controlButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(HulunoteFont.small)
            }
            .foregroundColor(.hulunoteAccent)
            .frame(width: 64, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.hulunoteInputBackground)
            )
        }
    }

    private func openDictionary(word: String) {
        guard !word.isEmpty else { return }
        let referenceVC = UIReferenceLibraryViewController(term: word)
        let topVC = UIApplication.getTopViewController()
        topVC?.present(referenceVC, animated: true)
    }
}
