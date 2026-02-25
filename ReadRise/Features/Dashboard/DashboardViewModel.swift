import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    var stats: Stats?
    var goal: Goal?
    var currentlyReading: [UserBook] = []
    var recentSessions: [ReadingSession] = []
    var isLoading = true
    var errorMessage: String?

    private let year = Calendar.current.component(.year, from: Date())

    func load(force: Bool = false) async {
        isLoading = true
        errorMessage = nil
        do {
            async let statsResult = AppCache.shared.stats(force: force)
            async let goalsResult = AppCache.shared.goals(year: year, force: force)
            async let libraryResult = AppCache.shared.library(force: force)

            let (s, goals, allBooks) = try await (statsResult, goalsResult, libraryResult)
            stats = s
            goal = goals.first { $0.goalType == "book_count" }
            currentlyReading = allBooks.filter { $0.shelf == "reading" }

            if let firstBook = currentlyReading.first {
                let sessResp: APIResponse<[ReadingSession]> = try await APIClient.shared.get(
                    "/api/library/\(firstBook.id)/sessions"
                )
                recentSessions = sessResp.data.filter { $0.endedAt != nil }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Goal computed properties

    var goalTarget: Int { goal?.target ?? 0 }

    var goalPercent: Double {
        guard goalTarget > 0, let s = stats else { return 0 }
        return min(Double(s.booksReadThisYear) / Double(goalTarget), 1.0)
    }

    var paceMessage: String? {
        guard goalTarget > 0, let s = stats else { return nil }
        let month = Calendar.current.component(.month, from: Date())
        let expected = Int((Double(goalTarget) * Double(month) / 12).rounded())
        if s.booksReadThisYear >= expected {
            let projected = month > 0 ? Int((Double(s.booksReadThisYear) / Double(month) * 12).rounded()) : 0
            return "On pace — projected \(projected) books this year."
        } else {
            let deficit = expected - s.booksReadThisYear
            return "Behind pace — \(deficit) more book\(deficit == 1 ? "" : "s") needed."
        }
    }
}
