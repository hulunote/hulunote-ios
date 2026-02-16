import SwiftUI

struct LoginView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel: LoginViewModel?

    var body: some View {
        ZStack {
            Color.hulunoteBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Gradient header
                    ZStack {
                        LinearGradient.hulunotePurple
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 0))

                        VStack(spacing: 8) {
                            Text("Hulunote")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)

                            Text("Outline your thoughts")
                                .font(HulunoteFont.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    // Login form card
                    VStack(spacing: 20) {
                        if let vm = viewModel {
                            // Email field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(HulunoteFont.smallMedium)
                                    .foregroundColor(.hulunoteTextSecondary)

                                TextField("Enter your email", text: Binding(
                                    get: { vm.email },
                                    set: { vm.email = $0 }
                                ))
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.hulunoteInputBackground)
                                .cornerRadius(10)
                                .foregroundColor(.hulunoteTextPrimary)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                            }

                            // Password field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(HulunoteFont.smallMedium)
                                    .foregroundColor(.hulunoteTextSecondary)

                                SecureField("Enter your password", text: Binding(
                                    get: { vm.password },
                                    set: { vm.password = $0 }
                                ))
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.hulunoteInputBackground)
                                .cornerRadius(10)
                                .foregroundColor(.hulunoteTextPrimary)
                                .textContentType(.password)
                            }

                            // Error message
                            if let error = vm.error {
                                Text(error)
                                    .font(HulunoteFont.small)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // Login button
                            Button {
                                Task { await vm.login() }
                            } label: {
                                ZStack {
                                    LinearGradient.hulunotePurple
                                        .frame(height: 48)
                                        .cornerRadius(24)

                                    if vm.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Log In")
                                            .font(HulunoteFont.bodyMedium)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .disabled(vm.isLoading)
                        }
                    }
                    .padding(32)
                    .background(Color.hulunoteCard)
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .offset(y: -40)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = LoginViewModel(authService: appViewModel.authService)
            }
        }
    }
}
