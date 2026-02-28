import Foundation

@Observable
@MainActor
final class BookDetailViewModel {
    var userBook: UserBook
    var sessions: [ReadingSession] = []
    var latestProgress: ProgressEntry?
    var review: ReviewData?
    var isLoading = true
    var errorMessage: String?

    // Session state
    var isStartingSession = false
    var isEndingSession = false
    var endPageText = ""

    // Progress input
    var newPageText = ""
    var isSavingProgress = false

    // Review
    var reviewRating: Double = 0
    var reviewBody = ""
    var isSavingReview = false

    // Delete
    var wasDeleted = false
    var isDeletingBook = false

    struct ReviewData: Decodable, Sendable {
        let id: String
        let rating: Double
        let body: String?
    }

    init(userBook: UserBook) {
        self.userBook = userBook
    }

    func load() async {
        isLoading = true
        do {
            async let sessResp: APIResponse<[ReadingSession]> = APIClient.shared.get("/api/library/\(userBook.id)/sessions")
            async let progResp: APIResponse<[ProgressEntry]> = APIClient.shared.get("/api/library/\(userBook.id)/progress")
            async let reviewResp: APIResponse<ReviewData?> = APIClient.shared.get("/api/library/\(userBook.id)/review")

            let (s, p, r) = try await (sessResp, progResp, reviewResp)
            sessions = s.data
            latestProgress = p.data.first
            review = r.data

            if let rev = r.data {
                reviewRating = rev.rating
                reviewBody = rev.body ?? ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var activeSession: ReadingSession? {
        sessions.first { $0.isActive }
    }

    var completedSessions: [ReadingSession] {
        sessions.filter { !$0.isActive }
    }

    var progress: Double? {
        guard let page = latestProgress?.page, let total = userBook.book.pageCount, total > 0 else { return nil }
        return Double(page) / Double(total)
    }

    // MARK: - Session actions

    func startSession() async {
        isStartingSession = true
        errorMessage = nil
        do {
            struct StartBody: Encodable { let pagesStart: Int? }
            let body = StartBody(pagesStart: latestProgress?.page)
            let resp: APIResponse<ReadingSession> = try await APIClient.shared.post(
                "/api/library/\(userBook.id)/sessions",
                body: body
            )
            let newSession = resp.data
            TimerService.shared.start(
                sessionId: newSession.id,
                userBookId: userBook.id,
                startedAt: newSession.startedAt
            )
            sessions.insert(newSession, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
        isStartingSession = false
    }

    func endSession() async {
        guard let session = activeSession else { return }
        isEndingSession = true
        errorMessage = nil
        do {
            struct EndBody: Encodable { let pagesEnd: Int? }
            let pagesEnd = Int(endPageText)
            let resp: APIResponse<ReadingSession> = try await APIClient.shared.patch(
                "/api/library/\(userBook.id)/sessions/\(session.id)",
                body: EndBody(pagesEnd: pagesEnd)
            )
            TimerService.shared.stop()
            endPageText = ""
            if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
                sessions[idx] = resp.data
            }
            // Refresh progress
            if let page = pagesEnd {
                struct ProgBody: Encodable { let page: Int }
                let _: APIResponse<ProgressEntry> = try await APIClient.shared.post(
                    "/api/library/\(userBook.id)/progress",
                    body: ProgBody(page: page)
                )
                await load()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isEndingSession = false
    }

    // MARK: - Progress

    func saveProgress() async {
        guard let page = Int(newPageText), page > 0 else { return }
        isSavingProgress = true
        do {
            struct ProgBody: Encodable { let page: Int }
            let resp: APIResponse<ProgressEntry> = try await APIClient.shared.post(
                "/api/library/\(userBook.id)/progress",
                body: ProgBody(page: page)
            )
            latestProgress = resp.data
            newPageText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isSavingProgress = false
    }

    // MARK: - Review

    func saveReview() async {
        guard reviewRating >= 1 else { return }
        isSavingReview = true
        do {
            struct ReviewBody: Encodable { let rating: Double; let body: String? }
            let _: APIResponse<ReviewData> = try await APIClient.shared.put(
                "/api/library/\(userBook.id)/review",
                body: ReviewBody(rating: reviewRating, body: reviewBody.isEmpty ? nil : reviewBody)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isSavingReview = false
    }

    // MARK: - Delete

    func deleteBook() async {
        isDeletingBook = true
        do {
            try await APIClient.shared.delete("/api/library/\(userBook.id)")
            await AppCache.shared.invalidateLibrary()
            await AppCache.shared.invalidateStats()
            wasDeleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isDeletingBook = false
    }

    // MARK: - Shelf

    func changeShelf(to shelf: String) async {
        do {
            struct ShelfBody: Encodable { let shelf: String }
            let resp: APIResponse<UserBook> = try await APIClient.shared.patch(
                "/api/library/\(userBook.id)",
                body: ShelfBody(shelf: shelf)
            )
            userBook = resp.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
