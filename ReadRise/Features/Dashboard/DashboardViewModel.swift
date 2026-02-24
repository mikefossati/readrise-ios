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

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let statsResult: APIResponse<Stats> = APIClient.shared.get("/api/stats")
            async let readingResult: APIResponse<[UserBook]> = APIClient.shared.get(
                "/api/library",
                queryItems: [URLQueryItem(name: "shelf", value: "reading")]
            )
            async let goalsResult: APIResponse<[Goal]> = APIClient.shared.get(
                "/api/goals",
                queryItems: [URLQueryItem(name: "year", value: "\(year)")]
            )

            let (statsResp, readingResp, goalsResp) = try await (statsResult, readingResult, goalsResult)
            stats = statsResp.data
            currentlyReading = readingResp.data
            goal = goalsResp.data.first { $0.goalType == "book_count" }

            if let firstBook = readingResp.data.first {
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
