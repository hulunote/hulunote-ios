import SwiftUI
import UIKit

/// A UITextView wrapper that supports:
/// - Inserting [[]] at cursor position (via toolbar button)
/// - Wrapping selected text with [[ ]] (via edit menu)
struct LinkableTextView: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont
    var textColor: UIColor
    var onContentChange: (String) -> Void
    var onSubmit: () -> Void
    var shouldInsertLink: Bool
    var onLinkInserted: () -> Void

    func makeUIView(context: Context) -> LinkUITextView {
        let textView = LinkUITextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = .clear
        textView.text = text
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.returnKeyType = .default
        return textView
    }

    func updateUIView(_ uiView: LinkUITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if shouldInsertLink {
            uiView.insertLinkBrackets()
            DispatchQueue.main.async {
                // Update text binding after insertion
                text = uiView.text
                onContentChange(uiView.text)
                onLinkInserted()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: LinkableTextView

        init(_ parent: LinkableTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.onContentChange(textView.text)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                parent.onSubmit()
                return false
            }
            return true
        }
    }
}

/// Custom UITextView subclass with [[link]] edit menu support
class LinkUITextView: UITextView {

    override func editMenu(for textRange: UITextRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        var actions = suggestedActions

        if let selectedText = text(in: textRange), !selectedText.isEmpty {
            let linkAction = UIAction(title: "[[\(selectedText)]]", image: UIImage(systemName: "link")) { [weak self] _ in
                guard let self, let range = self.selectedTextRange else { return }
                let selected = self.text(in: range) ?? ""
                self.replace(range, withText: "[[\(selected)]]")
            }
            actions.append(UIMenu(title: "", options: .displayInline, children: [linkAction]))
        }

        return UIMenu(children: actions)
    }

    func insertLinkBrackets() {
        let pos = selectedRange.location
        let nsText = NSMutableString(string: text ?? "")
        nsText.insert("[[]]", at: min(pos, nsText.length))
        text = nsText as String
        // Position cursor between the brackets
        selectedRange = NSRange(location: min(pos, nsText.length - 2) + 2, length: 0)
    }
}
