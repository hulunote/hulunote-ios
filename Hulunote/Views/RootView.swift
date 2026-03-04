import SwiftUI

struct RootView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        Group {
            if appViewModel.isLoggedIn {
                MainNavigationView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appViewModel.isLoggedIn)
    }
}

// MARK: - Navigation Routes

struct NoteListRoute: Hashable {
    let databaseId: String
    let databaseName: String
}

struct EditorRoute: Hashable {
    let noteId: String
    let noteTitle: String
    let rootNavId: String?
    let databaseId: String?
}

struct WordLearningRoute: Hashable {
    let databaseId: String
    let databaseName: String
}

struct R2D2Route: Hashable {
    let noteId: String
    let noteTitle: String
    let rootNavId: String?
}

// MARK: - Main Navigation

struct MainNavigationView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            DatabaseListView(path: $path)
                .navigationDestination(for: NoteListRoute.self) { route in
                    NoteListView(
                        databaseId: route.databaseId,
                        databaseName: route.databaseName,
                        path: $path
                    )
                }
                .navigationDestination(for: EditorRoute.self) { route in
                    OutlineEditorView(
                        noteId: route.noteId,
                        noteTitle: route.noteTitle,
                        rootNavId: route.rootNavId,
                        databaseId: route.databaseId,
                        path: $path
                    )
                }
                .navigationDestination(for: WordLearningRoute.self) { route in
                    WordLearningView(
                        databaseId: route.databaseId,
                        databaseName: route.databaseName
                    )
                }
                .navigationDestination(for: R2D2Route.self) { route in
                    R2D2ChatView(
                        noteId: route.noteId,
                        noteTitle: route.noteTitle,
                        rootNavId: route.rootNavId
                    )
                }
        }
        .tint(Color.hulunoteAccent)
    }
}
