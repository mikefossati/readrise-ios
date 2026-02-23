import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AuthService.self) private var auth
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color(hex: "#faf8f4").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + headline
                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(hex: "#e8923a"))

                    Text("ReadRise")
                        .font(.custom("Georgia", size: 36).bold())
                        .foregroundStyle(Color(hex: "#1a1a2e"))

                    Text("Track books. Build a streak.\nUnderstand how you read.")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#7a7068"))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Sign in buttons
                VStack(spacing: 12) {
                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { _ in
                        // Handled via AuthService
                    }
                    .frame(height: 50)
                    .cornerRadius(10)
                    .onTapGesture {
                        Task {
                            isLoading = true
                            await auth.signInWithApple()
                            isLoading = false
                        }
                    }

                    // Continue with Google
                    Button {
                        Task {
                            isLoading = true
                            await auth.signInWithGoogle()
                            isLoading = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                            Text("Continue with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundStyle(Color(hex: "#1a1a2e"))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "#ddd5c8"), lineWidth: 1)
                        )
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }

            if isLoading {
                Color.black.opacity(0.1).ignoresSafeArea()
                ProgressView()
            }
        }
    }
}
