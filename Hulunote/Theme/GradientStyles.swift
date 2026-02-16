import SwiftUI

extension LinearGradient {
    static var hulunotePurple: LinearGradient {
        LinearGradient(
            colors: [Color.hulunotePurpleStart, Color.hulunotePurpleEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var hulunoteDarkBackground: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "1A1A2E"), Color(hex: "2D2D44")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
