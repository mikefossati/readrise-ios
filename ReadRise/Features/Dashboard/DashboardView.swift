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

    private var year: Int { Calendar.current.component(.year, from: Date()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if vm.isLoading {
                        DashboardSkeletonView()
                    } else {
                        headerSection
                        currentlyReadingSection
                        goalSection
                        statRowSection
                        streakBadge
                        recentSessionsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.rrBackground)
            .toolbar(.hidden, for: .navigationBar)
            .refreshable { await vm.load(force: true) }
            .navigationDestination(item: $selectedBook) { book in
                BookDetailView(userBook: book)
            }
        }
        .task { await vm.load() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(greeting).")
                .font(.custom("Georgia", size: 20).bold())
                .foregroundStyle(Color.rrLabel)
            Spacer()
            Text(today)
                .font(.caption)
                .foregroundStyle(Color.rrSecondaryLabel)
        }
    }

    // MARK: - Currently reading (top — most actionable)

    @ViewBuilder
    private var currentlyReadingSection: some View {
        if !vm.currentlyReading.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Currently reading")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.rrLabel)
                ForEach(vm.currentlyReading) { book in
                    Button {
                        Haptic.impact(.light)
                        selectedBook = book
                    } label: {
                        CurrentlyReadingRow(userBook: book)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Year goal ring

    private var goalSection: some View {
        GoalCard(
            year: year,
            booksRead: vm.stats?.booksReadThisYear ?? 0,
            goalTarget: vm.goalTarget,
            goalPercent: vm.goalPercent,
            paceMessage: vm.paceMessage
        )
    }

    // MARK: - Stats grid (with icons)

    private var statRowSection: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: 4),
            spacing: 10
        ) {
            StatCard(icon: "book.fill",
                     value: "\(vm.stats?.booksReadThisYear ?? 0)",
                     label: "books\nthis year")
            StatCard(icon: "doc.text.fill",
                     value: vm.stats?.totalPagesAllTime.formatted() ?? "0",
                     label: "pages\nread")
            StatCard(icon: "clock.fill",
                     value: "\(vm.stats?.totalHoursAllTime ?? 0)",
                     label: "hours\nread")
            StatCard(icon: "speedometer",
                     value: vm.stats?.averagePagesPerHour.map { "\($0)" } ?? "—",
                     label: "pages\nper hr")
        }
    }

    // MARK: - Streak badge (compact inline)

    private var streakBadge: some View {
        let streak = vm.stats?.streak.currentStreak ?? 0
        return HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.subheadline)
                .foregroundStyle(streak > 0 ? Color.rrAmber : Color.rrSecondaryLabel)
            Text(streak > 0
                 ? "\(streak)-day streak · Keep it going"
                 : "Start your streak — read today")
                .font(.subheadline)
                .foregroundStyle(streak > 0 ? Color.rrLabel : Color.rrSecondaryLabel)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(streak > 0 ? Color.rrAmberTint : Color.rrCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.rrBorder, lineWidth: 0.5))
    }

    // MARK: - Recent sessions

    @ViewBuilder
    private var recentSessionsSection: some View {
        if !vm.recentSessions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent sessions")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.rrLabel)
                ForEach(vm.recentSessions.prefix(3)) { session in
                    SessionRow(session: session)
                }
            }
        }
    }
}

// MARK: - GoalCard

private struct GoalCard: View {
    let year: Int
    let booksRead: Int
    let goalTarget: Int
    let goalPercent: Double
    let paceMessage: String?

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.rrBorder, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: goalTarget > 0 ? CGFloat(goalPercent) : 0)
                    .stroke(
                        Color.rrAmber,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8), value: goalPercent)
                VStack(spacing: 1) {
                    Text("\(booksRead)")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(Color.rrLabel)
                    if goalTarget > 0 {
                        Text("/ \(goalTarget)")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.rrSecondaryLabel)
                    }
                }
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(year) Reading Goal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.rrLabel)
                Text(paceMessage ?? (goalTarget > 0
                    ? "\(Int(goalPercent * 100))% complete"
                    : "Set a goal in the Goals tab"))
                    .font(.caption)
                    .foregroundStyle(Color.rrSecondaryLabel)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.rrCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.rrBorder, lineWidth: 0.5))
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.rrAmber)
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(Color.rrLabel)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.rrSecondaryLabel)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.rrCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.rrBorder, lineWidth: 0.5))
    }
}

// MARK: - CurrentlyReadingRow

private struct CurrentlyReadingRow: View {
    let userBook: UserBook

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: userBook.book.coverURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.rrFill)
            }
            .frame(width: 44, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                Text(userBook.book.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(Color.rrLabel)
                Text(userBook.book.firstAuthor)
                    .font(.caption)
                    .foregroundStyle(Color.rrSecondaryLabel)
            }

            Spacer()

            Text("Continue")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.rrAmber)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.rrCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.rrBorder, lineWidth: 0.5))
    }
}

// MARK: - SessionRow

private struct SessionRow: View {
    let session: ReadingSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startedAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.rrLabel)
                if session.durationSeconds != nil {
                    Text(session.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(Color.rrSecondaryLabel)
                }
            }
            Spacer()
            if let pph = session.pagesPerHour {
                Text("\(Int(pph)) p/hr")
                    .font(.caption)
                    .foregroundStyle(Color.rrSecondaryLabel)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.rrCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.rrBorder, lineWidth: 0.5))
    }
}

// MARK: - Skeleton

private struct DashboardSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.rrFill)
                    .frame(width: 150, height: 22)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.rrFill)
                    .frame(width: 60, height: 14)
            }
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.rrCard)
                .frame(height: 104)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                spacing: 10
            ) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.rrFill)
                        .frame(height: 76)
                }
            }
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.rrCard)
                .frame(height: 44)
        }
        .redacted(reason: .placeholder)
    }
}
