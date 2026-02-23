import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    var stats: Stats?
    var currentlyReading: [UserBook] = []
    var recentSessions: [ReadingSession] = []
    var isLoading = true
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let statsResult: APIResponse<Stats> = APIClient.shared.get("/api/stats")
            async let readingResult: APIResponse<[UserBook]> = APIClient.shared.get(
                "/api/library",
                queryItems: [URLQueryItem(name: "shelf", value: "reading")]
            )

            let (statsResp, readingResp) = try await (statsResult, readingResult)
            stats = statsResp.data
            currentlyReading = readingResp.data

            // Fetch recent sessions for the first currently-reading book
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
}
