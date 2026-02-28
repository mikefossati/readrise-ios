import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    private var network = NetworkMonitor.shared

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                    .tag(0)

                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "books.vertical.fill")
                    }
                    .tag(1)

                GoalsView()
                    .tabItem {
                        Label("Goals", systemImage: "target")
                    }
                    .tag(2)

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(3)
            }
            .tint(Color.rrAmber)

            if !network.isConnected {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                    Text("Offline — showing cached data")
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.rrAmber.opacity(0.15))
                .clipShape(Capsule())
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: network.isConnected)
            }
        }
    }
}
