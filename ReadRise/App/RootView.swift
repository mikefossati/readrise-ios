import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth: AuthService

    private var isUITesting: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--uitesting")
        #else
        false
        #endif
    }

    var body: some View {
        Group {
            if isUITesting {
                // Bypass auth entirely so UI tests start on MainTabView
                MainTabView()
            } else if auth.isLoading {
                SplashView()
            } else if auth.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.2), value: auth.isLoading)
    }
}
