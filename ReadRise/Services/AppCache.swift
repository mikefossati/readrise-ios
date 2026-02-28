import Foundation

/// Shared TTL-gated in-memory cache for API data.
/// Thread-safe via Swift actor isolation.
actor AppCache {
    static let shared = AppCache()
    private init() {}

    // MARK: - Disk persistence helpers

    private let cacheDir: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("rr_appcache")
    }()

    private func write<T: Encodable>(_ value: T, name: String) {
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        try? JSONEncoder().encode(value).write(to: cacheDir.appendingPathComponent("\(name).json"))
    }

    private func read<T: Decodable>(_ type: T.Type, name: String) -> T? {
        guard let data = try? Data(contentsOf: cacheDir.appendingPathComponent("\(name).json")) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Stats (3-minute TTL)

    private var cachedStats: Stats?
    private var statsAt: Date?
    private let statsTTL: TimeInterval = 180

    func stats(force: Bool = false) async throws -> Stats {
        if !force, let s = cachedStats, let t = statsAt, Date().timeIntervalSince(t) < statsTTL {
            return s
        }
        do {
            let r: APIResponse<Stats> = try await APIClient.shared.get("/api/stats")
            cachedStats = r.data
            statsAt = Date()
            write(r.data, name: "stats")
            return r.data
        } catch {
            if let disk = read(Stats.self, name: "stats") { return disk }
            throw error
        }
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
        do {
            let r: APIResponse<[Goal]> = try await APIClient.shared.get(
                "/api/goals",
                queryItems: [URLQueryItem(name: "year", value: "\(year)")]
            )
            cachedGoals = r.data
            goalsAt = Date()
            write(r.data, name: "goals_\(year)")
            return r.data
        } catch {
            if let disk = read([Goal].self, name: "goals_\(year)") { return disk }
            throw error
        }
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
        do {
            let r: APIResponse<[UserBook]> = try await APIClient.shared.get("/api/library")
            cachedLibrary = r.data
            libraryAt = Date()
            write(r.data, name: "library")
            return r.data
        } catch {
            if let disk = read([UserBook].self, name: "library") { return disk }
            throw error
        }
    }

    func invalidateLibrary() {
        cachedLibrary = []
        libraryAt = nil
    }
}
