import Foundation

/// Shared TTL-gated in-memory cache for API data.
/// Thread-safe via Swift actor isolation.
actor AppCache {
    static let shared = AppCache()
    private init() {}

    // MARK: - Stats (3-minute TTL)

    private var cachedStats: Stats?
    private var statsAt: Date?
    private let statsTTL: TimeInterval = 180

    func stats(force: Bool = false) async throws -> Stats {
        if !force, let s = cachedStats, let t = statsAt, Date().timeIntervalSince(t) < statsTTL {
            return s
        }
        let r: APIResponse<Stats> = try await APIClient.shared.get("/api/stats")
        cachedStats = r.data
        statsAt = Date()
        return r.data
    }

    func invalidateStats() {
        cachedStats = nil
        statsAt = nil
    }

    // MARK: - Goals (10-minute TTL)

    private var cachedGoals: [Goal] = []
    private var goalsAt: Date?
    private let goalsTTL: TimeInterval = 600

    func goals(year: Int, force: Bool = false) async throws -> [Goal] {
        if !force, let t = goalsAt, Date().timeIntervalSince(t) < goalsTTL {
            return cachedGoals
        }
        let r: APIResponse<[Goal]> = try await APIClient.shared.get(
            "/api/goals",
            queryItems: [URLQueryItem(name: "year", value: "\(year)")]
        )
        cachedGoals = r.data
        goalsAt = Date()
        return r.data
    }

    func invalidateGoals() {
        cachedGoals = []
        goalsAt = nil
    }

    // MARK: - Library (2-minute TTL)

    private var cachedLibrary: [UserBook] = []
    private var libraryAt: Date?
    private let libraryTTL: TimeInterval = 120

    func library(force: Bool = false) async throws -> [UserBook] {
        if !force, let t = libraryAt, Date().timeIntervalSince(t) < libraryTTL {
            return cachedLibrary
        }
        let r: APIResponse<[UserBook]> = try await APIClient.shared.get("/api/library")
        cachedLibrary = r.data
        libraryAt = Date()
        return r.data
    }

    func invalidateLibrary() {
        cachedLibrary = []
        libraryAt = nil
    }
}
