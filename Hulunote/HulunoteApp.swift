import SwiftUI

@main
struct HulunoteApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
