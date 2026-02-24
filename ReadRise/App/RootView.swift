import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth: AuthService

    var body: some View {
        Group {
            if auth.isLoading {
                Color.rrBackground
                    .ignoresSafeArea()
                    .overlay(ProgressView().tint(Color.rrAmber))
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
