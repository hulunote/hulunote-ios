# Hulunote iOS

A native iOS outline editor for [Hulunote](https://www.hulunote.top) — a hierarchical note-taking application built with SwiftUI.

![](./ios-demo-all.png)

## Features

- **Outline Editing** — Create, edit, and organize notes as hierarchical outlines with unlimited nesting depth
- **Indent / Outdent** — Restructure your outline by moving blocks between levels via the editor toolbar
- **Collapse / Expand** — Focus on what matters by collapsing and expanding outline branches
- **Auto-Save** — Content changes are debounced and saved automatically (500ms delay)
- **Database & Note Management** — Browse databases, create/delete/search notes, mark shortcuts
- **Dark Theme** — Purpose-built dark UI with purple gradient accents
- **Secure Auth** — JWT-based authentication with Keychain token storage

## Screenshots

*Coming soon*

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/hulunote/hulunote-ios.git
cd hulunote-ios
```

### 2. Generate the Xcode project

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the `.xcodeproj` from `project.yml`.

```bash
brew install xcodegen
xcodegen generate
```

### 3. Build and run

Open `Hulunote.xcodeproj` in Xcode, select an iPhone simulator (iOS 17+), and hit **Run** (Cmd+R).

### 4. Backend

The app connects to the Hulunote backend API. By default it points to `https://www.hulunote.top`. To use a local backend, update the base URL in `AppViewModel.swift`:

```swift
init(baseURL: URL = URL(string: "http://localhost:6689")!) {
```

The backend source is available at [hulunote-rust](https://github.com/hulunote/hulunote-rust).

## Architecture

The app follows **MVVM** with pure SwiftUI and zero third-party dependencies.

```
Hulunote/
  HulunoteApp.swift                 # App entry point, dark theme
  Models/                           # Codable data models (Auth, Database, Note, Nav)
  Network/                          # URLSession-based API client with JWT injection
  Services/                         # Business logic (Auth, Database, Note, Nav, Keychain)
  OutlineTree/                      # DFS tree builder: flat NavInfo[] -> display list
  ViewModels/                       # Observable state for each screen
  Views/                            # SwiftUI views (Login, Database, Note, Editor)
  Theme/                            # Color palette, typography, gradients
  Utilities/                        # Extensions (Color hex initializer)
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| No third-party deps | URLSession, Codable, Keychain Services, and `@Observable` cover all needs |
| `@Observable` macro | Fine-grained observation, less boilerplate than `ObservableObject` |
| Custom `CodingKeys` | Backend uses kebab-case JSON keys (e.g. `"database-id"`, `"hulunote-notes/title"`) |
| Flat tree rendering | Server returns flat `[NavInfo]` with `parid` refs; DFS produces `[OutlineNode]` with depth for `LazyVStack` |
| Float ordering | `same-deep-order` (Float) enables insert-between without reindexing siblings |
| Debounced save | Per-block 500ms debounce via `Task.sleep` + cancellation prevents excessive API calls |

## API Endpoints

All endpoints are `POST` with JSON bodies. Auth via `X-FUNCTOR-API-TOKEN` header.

| Endpoint | Description |
|----------|-------------|
| `/login/web-login` | Authenticate with email/password |
| `/hulunote/get-database-list` | List user databases |
| `/hulunote/get-note-list` | List notes in a database (paginated) |
| `/hulunote/new-note` | Create a new note |
| `/hulunote/get-note-navs` | Get all outline nodes for a note |
| `/hulunote/create-or-update-nav` | Create or update an outline node |

## Contributing

Contributions are welcome. Please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
