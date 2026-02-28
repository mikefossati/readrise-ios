import SwiftUI

struct AuthView: View {
    @Environment(AuthService.self) private var auth: AuthService
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.rrBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.rrAmber)

                    Text("ReadRise")
                        .font(.custom("Georgia", size: 36).bold())
                        .foregroundStyle(Color.rrLabel)

                    Text("Track books. Build a streak.\nUnderstand how you read.")
                        .font(.subheadline)
                        .foregroundStyle(Color.rrSecondaryLabel)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 12) {
                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Custom Apple Sign In button — calls our ASAuthorizationController directly.
                    // Using SignInWithAppleButton + onTapGesture triggers two controllers at once.
                    Button {
                        Task {
                            isLoading = true
                            await auth.signInWithApple()
                            isLoading = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.body.weight(.semibold))
                            Text("Sign in with Apple")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.label))
                        .foregroundStyle(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isLoading)
                    .accessibilityIdentifier("auth.signInApple")

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
                        .background(Color.rrCard)
                        .foregroundStyle(Color.rrLabel)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.rrBorder, lineWidth: 1))
                    }
                    .disabled(isLoading)
                    .accessibilityIdentifier("auth.signInGoogle")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }

            if isLoading {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
    }
}
