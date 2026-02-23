import Foundation

@Observable
@MainActor
final class GoalsViewModel {
    var goal: Goal?
    var stats: Stats?
    var isLoading = true
    var isSaving = false
    var errorMessage: String?
    var targetText = ""

    private let year = Calendar.current.component(.year, from: Date())

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let goalsResp: APIResponse<[Goal]> = APIClient.shared.get(
                "/api/goals",
                queryItems: [URLQueryItem(name: "year", value: "\(year)")]
            )
            async let statsResp: APIResponse<Stats> = APIClient.shared.get("/api/stats")

            let (g, s) = try await (goalsResp, statsResp)
            goal = g.data.first { $0.goalType == "book_count" }
            stats = s.data
            targetText = goal.map { "\($0.target)" } ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func save() async {
        guard let target = Int(targetText), target > 0 else {
            errorMessage = "Enter a number between 1 and 9999."
            return
        }
        isSaving = true
        errorMessage = nil
        do {
            struct GoalBody: Encodable { let year: Int; let goalType: String; let target: Int }
            let resp: APIResponse<Goal> = try await APIClient.shared.post(
                "/api/goals",
                body: GoalBody(year: year, goalType: "book_count", target: target)
            )
            goal = resp.data
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    var booksRead: Int { stats?.booksReadThisYear ?? 0 }
    var goalTarget: Int { goal?.target ?? 0 }
    var percent: Double {
        guard goalTarget > 0 else { return 0 }
        return min(Double(booksRead) / Double(goalTarget), 1.0)
    }

    var paceMessage: String? {
        guard goalTarget > 0, let _ = stats else { return nil }
        let month = Calendar.current.component(.month, from: Date())
        let expected = Int((Double(goalTarget) * Double(month) / 12).rounded())
        if booksRead >= expected {
            let projected = month > 0 ? Int((Double(booksRead) / Double(month) * 12).rounded()) : 0
            return "On pace — projected to finish \(projected) books this year."
        } else {
            let deficit = expected - booksRead
            return "Behind pace — \(deficit) more book\(deficit == 1 ? "" : "s") needed to be on track."
        }
    }
}
