import Foundation
import AVFoundation

@Observable
final class NoteTTSViewModel {
    var paragraphs: [String] = []
    var currentParagraphIndex: Int = -1
    var currentWordLocation: Int = 0
    var currentWordLength: Int = 0
    var isPlaying: Bool = false
    var isPaused: Bool = false
    var isLoading: Bool = false
    var error: String?

    let noteTitle: String

    private let synth = AVSpeechSynthesizer()
    private var delegate: TTSDelegate?
    private let navService: NavService
    private let noteId: String
    private let rootNavId: String?

    init(noteId: String, noteTitle: String, rootNavId: String?, apiClient: APIClient) {
        self.noteId = noteId
        self.noteTitle = noteTitle
        self.rootNavId = rootNavId
        self.navService = NavService(api: apiClient)
        let del = TTSDelegate()
        self.delegate = del
        self.synth.delegate = del
        del.viewModel = self
    }

    // MARK: - Load

    @MainActor
    func loadContent() async {
        isLoading = true
        error = nil
        do {
            let navs = try await navService.getNavList(noteId: noteId)

            var actualRootNavId = rootNavId
            if actualRootNavId == nil {
                let nilUUID = OutlineTreeBuilder.nilUUID
                let rootNav = navs.first { nav in
                    nav.parid == nil
                        || nav.parid == nilUUID
                        || nav.parid == nav.id
                        || nav.parid?.isEmpty == true
                }
                actualRootNavId = rootNav?.id
            }

            let allNodes = OutlineTreeBuilder.buildDisplayList(
                navList: navs,
                rootNavId: actualRootNavId,
                collapsedIds: []
            )

            self.paragraphs = allNodes
                .map { Self.cleanToEnglish($0.content) }
                .filter { !$0.isEmpty }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Playback Controls

    func startSpeaking() {
        guard !paragraphs.isEmpty else { return }
        configureAudioSession()
        synth.stopSpeaking(at: .immediate)
        currentParagraphIndex = 0
        currentWordLocation = 0
        currentWordLength = 0
        isPlaying = true
        isPaused = false
        speakCurrentParagraph()
    }

    func togglePlayPause() {
        if isPaused {
            synth.continueSpeaking()
            isPaused = false
            isPlaying = true
        } else if isPlaying {
            synth.pauseSpeaking(at: .word)
            isPaused = true
            isPlaying = false
        } else {
            startSpeaking()
        }
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
        currentParagraphIndex = -1
        currentWordLocation = 0
        currentWordLength = 0
    }

    // MARK: - Internal

    fileprivate func speakCurrentParagraph() {
        guard currentParagraphIndex >= 0, currentParagraphIndex < paragraphs.count else {
            isPlaying = false
            isPaused = false
            return
        }

        let text = paragraphs[currentParagraphIndex]
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectVoice(for: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.1
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.3

        currentWordLocation = 0
        currentWordLength = 0
        synth.speak(utterance)
    }

    fileprivate func onWillSpeak(range: NSRange) {
        currentWordLocation = range.location
        currentWordLength = range.length
    }

    fileprivate func onFinishUtterance() {
        currentParagraphIndex += 1
        if currentParagraphIndex < paragraphs.count {
            speakCurrentParagraph()
        } else {
            isPlaying = false
            isPaused = false
        }
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func selectVoice(for text: String) -> AVSpeechSynthesisVoice? {
        if let voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.enhanced.en-US.Samantha") {
            return voice
        }
        if let voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact") {
            return voice
        }
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    private static func cleanToEnglish(_ text: String) -> String {
        // Only keep English letters, digits, spaces, and basic sentence punctuation
        let cleaned = text.unicodeScalars.map { scalar -> Character in
            let v = scalar.value
            if (v >= 0x41 && v <= 0x5A) || (v >= 0x61 && v <= 0x7A) { return Character(scalar) } // A-Z a-z
            if v >= 0x30 && v <= 0x39 { return Character(scalar) } // 0-9
            if scalar == " " || scalar == "'" { return Character(scalar) } // space, apostrophe
            return " "
        }
        // Collapse multiple spaces and trim
        return String(cleaned)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    deinit {
        synth.stopSpeaking(at: .immediate)
    }
}

// MARK: - Delegate

private class TTSDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var viewModel: NoteTTSViewModel?

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.viewModel?.onWillSpeak(range: characterRange)
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.viewModel?.onFinishUtterance()
        }
    }
}
