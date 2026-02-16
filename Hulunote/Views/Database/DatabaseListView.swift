import SwiftUI

struct DatabaseListView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Binding var path: NavigationPath
    @State private var viewModel: DatabaseListViewModel?

    var body: some View {
        ZStack {
            Color.hulunoteBackground.ignoresSafeArea()

            if let vm = viewModel {
                if vm.isLoading && vm.databases.isEmpty {
                    ProgressView()
                        .tint(.hulunoteAccent)
                } else if let error = vm.error, vm.databases.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.hulunoteTextSecondary)
                        Text(error)
                            .font(HulunoteFont.body)
                            .foregroundColor(.hulunoteTextSecondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await vm.loadDatabases() }
                        }
                        .foregroundColor(.hulunoteAccent)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.databases) { db in
                                DatabaseCardView(database: db) {
                                    path.append(NoteListRoute(
                                        databaseId: db.id,
                                        databaseName: db.name
                                    ))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                    .refreshable {
                        await vm.loadDatabases()
                    }
                }
            }
        }
        .navigationTitle("Databases")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel?.logout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.hulunoteTextSecondary)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = DatabaseListViewModel(
                    authService: appViewModel.authService,
                    apiClient: appViewModel.apiClient
                )
            }
        }
        .task {
            await viewModel?.loadDatabases()
        }
    }
}
