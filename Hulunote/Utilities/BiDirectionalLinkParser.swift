import Foundation
import SwiftUI

enum BiDirectionalLinkParser {
    private static let linkPattern = try! NSRegularExpression(pattern: "\\[\\[([^\\]]+)\\]\\]")

    /// Extract all linked note titles from content
    static func extractLinkTitles(from content: String) -> [String] {
        let range = NSRange(content.startIndex..., in: content)
        let matches = linkPattern.matches(in: content, range: range)
        return matches.compactMap { match in
            guard let titleRange = Range(match.range(at: 1), in: content) else { return nil }
            return String(content[titleRange])
        }
    }

    /// Check if content contains any [[...]] links
    static func containsLinks(_ content: String) -> Bool {
        let range = NSRange(content.startIndex..., in: content)
        return linkPattern.firstMatch(in: content, range: range) != nil
    }

    /// Parse content into an AttributedString with link styling
    static func parseToAttributedString(_ content: String) -> AttributedString {
        let nsContent = content as NSString
        let fullRange = NSRange(location: 0, length: nsContent.length)
        let matches = linkPattern.matches(in: content, range: fullRange)

        guard !matches.isEmpty else {
            return AttributedString(content)
        }

        var result = AttributedString()
        var lastEnd = content.startIndex

        for match in matches {
            guard let matchRange = Range(match.range, in: content),
                  let titleRange = Range(match.range(at: 1), in: content) else { continue }

            // Add plain text before this match
            if lastEnd < matchRange.lowerBound {
                result.append(AttributedString(String(content[lastEnd..<matchRange.lowerBound])))
            }

            // Add the link text (just the title, without [[ ]])
            let title = String(content[titleRange])
            var linkAttr = AttributedString(title)
            let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
            linkAttr.link = URL(string: "hulunote://note/\(encoded)")
            linkAttr.foregroundColor = Color.hulunoteAccent
            linkAttr.underlineStyle = .single
            result.append(linkAttr)

            lastEnd = matchRange.upperBound
        }

        // Add remaining plain text
        if lastEnd < content.endIndex {
            result.append(AttributedString(String(content[lastEnd...])))
        }

        return result
    }
}
