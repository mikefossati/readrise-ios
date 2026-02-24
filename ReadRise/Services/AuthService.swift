import Foundation
import CryptoKit
import Supabase
import AuthenticationServices
import UIKit

@Observable
@MainActor
final class AuthService: NSObject {
    var isAuthenticated = false
    var isLoading = true
    var errorMessage: String?

    override init() {
        super.init()
        startListening()
    }

    // No stored task — [weak self] means the loop exits naturally if AuthService
    // is ever deallocated. Task is retained by the runtime until it finishes.
    private func startListening() {
        Task { [weak self] in
            // authStateChanges is a plain AsyncStream — no `await` needed here
            for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
                guard let self else { return }
                switch event {
                case .initialSession:
                    self.isAuthenticated = session != nil
                    self.isLoading = false
                case .signedIn:
                    self.isAuthenticated = true
                    self.isLoading = false
                case .signedOut, .userDeleted:
                    self.isAuthenticated = false
                    self.isLoading = false
                default:
                    break
                }
            }
        }
    }

    // MARK: - Sign in with Apple

    func signInWithApple() async {
        errorMessage = nil
        do {
            let (idToken, nonce) = try await performAppleSignIn()
            try await SupabaseManager.shared.client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign in with Google (ASWebAuthenticationSession)

    func signInWithGoogle() async {
        errorMessage = nil
        do {
            // launchFlow: receives the Supabase auth URL, opens it via ASWebAuthenticationSession,
            // returns the callback URL (readrise://auth-callback?code=...) so supabase-swift
            // can exchange the code for a session internally.
            try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "readrise://auth-callback")!
            ) { [weak self] url -> URL in
                guard let self else { throw URLError(.cancelled) }
                return try await self.presentWebAuthSession(url: url)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Opens the OAuth URL in ASWebAuthenticationSession and returns the callback URL.
    private func presentWebAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "readrise"
            ) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: error ?? URLError(.cancelled))
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    func handleOAuthCallback(url: URL) async {
        do {
            try await SupabaseManager.shared.client.auth.session(from: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign out

    func signOut() async {
        do {
            try await SupabaseManager.shared.client.auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Apple Sign In helpers

    private func performAppleSignIn() async throws -> (String, String) {
        return try await withCheckedThrowingContinuation { continuation in
            let nonce = randomNonceString()
            let hashedNonce = sha256(nonce)

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = hashedNonce

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate { result in
                switch result {
                case .success(let credential):
                    guard let idToken = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else {
                        continuation.resume(throwing: AuthError.appleSignInFailed)
                        return
                    }
                    continuation.resume(returning: (idToken, nonce))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
            objc_setAssociatedObject(controller, &AppleSignInDelegate.key, delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Error

enum AuthError: LocalizedError {
    case appleSignInFailed
    var errorDescription: String? { "Apple Sign In failed." }
}

// MARK: - Apple Sign In Delegate

private final class AppleSignInDelegate: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding,
    @unchecked Sendable
{
    nonisolated(unsafe) static var key: UInt8 = 0
    let completion: @Sendable (Result<ASAuthorizationAppleIDCredential, Error>) -> Void

    init(completion: @escaping @Sendable (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            completion(.success(credential))
        } else {
            completion(.failure(AuthError.appleSignInFailed))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
