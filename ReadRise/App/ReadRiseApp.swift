import SwiftUI

@main
struct ReadRiseApp: App {
    @State private var authService = AuthService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .onOpenURL { url in
                    // Handle OAuth callback (Google sign-in redirect)
                    guard url.scheme == "readrise" else { return }
                    Task { await authService.handleOAuthCallback(url: url) }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        TimerService.shared.refreshFromForeground()
                    }
                }
        }
    }
}
