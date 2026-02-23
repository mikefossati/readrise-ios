import SwiftUI

struct DashboardView: View {
    @State private var vm = DashboardViewModel()
    @State private var selectedBook: UserBook?

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private var today: String {
        Date().formatted(.dateTime.month(.wide).day())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if vm.isLoading {
                        DashboardSkeletonView()
                    } else {
                        headerSection
                        if let stats = vm.stats {
                            streakHeroSection(stats: stats)
                            statRowSection(stats: stats)
                        }
                        currentlyReadingSection
                        recentSessionsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(hex: "#faf8f4"))
            .navigationTitle("")
            .navigationBarHidden(true)
            .refreshable { await vm.load() }
        }
        .task { await vm.load() }
        .navigationDestination(item: $selectedBook) { book in
            BookDetailView(userBook: book)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(greeting).")
                    .font(.custom("Georgia", size: 24).bold())
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                Text(today)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "#7a7068"))
            }
            Spacer()
        }
    }

    private func streakHeroSection(stats: Stats) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(stats.streak.currentStreak > 0 ? Color(hex: "#e8923a") : Color(hex: "#7a7068"))

            VStack(alignment: .leading, spacing: 2) {
                Text(stats.streak.currentStreak > 0
                     ? "\(stats.streak.currentStreak)-day streak"
                     : "Start your streak")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                Text(stats.streak.currentStreak > 0
                     ? "Keep it going — log a session today."
                     : "Read today to start a streak.")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#7a7068"))
            }
            Spacer()

            if let book = vm.currentlyReading.first {
                Button("Continue") {
                    selectedBook = book
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#e8923a"))
                .font(.caption.weight(.semibold))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "#fef3e2"))
        .cornerRadius(14)
    }

    private func statRowSection(stats: Stats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                             GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatCard(value: "\(stats.booksReadThisYear)", label: "books\nthis year")
            StatCard(value: stats.totalPagesAllTime.formatted(), label: "pages\nread")
            StatCard(value: "\(stats.totalHoursAllTime)", label: "hours\nread")
            StatCard(value: stats.averagePagesPerHour.map { "\($0)" } ?? "—", label: "pages\nper hr")
        }
    }

    private var currentlyReadingSection: some View {
        Group {
            if !vm.currentlyReading.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Currently reading")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "#1a1a2e"))

                    ForEach(vm.currentlyReading) { book in
                        Button { selectedBook = book } label: {
                            CurrentlyReadingRow(userBook: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var recentSessionsSection: some View {
        Group {
            if !vm.recentSessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent sessions")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "#1a1a2e"))

                    ForEach(vm.recentSessions.prefix(3)) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
    }
}

// MARK: - Sub-components

private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(Color(hex: "#1a1a2e"))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#7a7068"))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#ddd5c8"), lineWidth: 0.5))
    }
}

private struct CurrentlyReadingRow: View {
    let userBook: UserBook

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: userBook.book.coverURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color(hex: "#ddd5c8"))
            }
            .frame(width: 44, height: 64)
            .cornerRadius(6)
            .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(userBook.book.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                Text(userBook.book.firstAuthor)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#7a7068"))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color(hex: "#7a7068"))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#ddd5c8"), lineWidth: 0.5))
    }
}

private struct SessionRow: View {
    let session: ReadingSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startedAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                if let dur = session.durationSeconds {
                    Text(session.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#7a7068"))
                }
            }
            Spacer()
            if let pph = session.pagesPerHour {
                Text("\(Int(pph)) p/hr")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#7a7068"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#ddd5c8"), lineWidth: 0.5))
    }
}

private struct DashboardSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8).fill(Color(hex: "#ddd5c8")).frame(height: 32).frame(maxWidth: .infinity, alignment: .leading).frame(width: 200)
            RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#fef3e2")).frame(height: 72)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#ddd5c8")).frame(height: 60)
                }
            }
        }
        .redacted(reason: .placeholder)
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: Double
        switch hex.count {
        case 6:
            (r, g, b, a) = (Double((int >> 16) & 0xFF) / 255, Double((int >> 8) & 0xFF) / 255, Double(int & 0xFF) / 255, 1)
        case 8:
            (r, g, b, a) = (Double((int >> 24) & 0xFF) / 255, Double((int >> 16) & 0xFF) / 255, Double((int >> 8) & 0xFF) / 255, Double(int & 0xFF) / 255)
        default:
            (r, g, b, a) = (0, 0, 0, 1)
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
