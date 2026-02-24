import Foundation
import Supabase

// MARK: - Errors

enum APIError: LocalizedError {
    case notAuthenticated
    case bookLimitReached
    case serverError(Int, String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please sign in to continue."
        case .bookLimitReached: return "You've reached the 50-book limit. Visit readrise.app to upgrade."
        case .serverError(let code, let msg): return "Server error \(code): \(msg)"
        case .decodingError(let e): return "Data error: \(e.localizedDescription)"
        case .networkError(let e): return e.localizedDescription
        }
    }
}

// MARK: - API Client

final class APIClient: Sendable {
    static let shared = APIClient()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    // MARK: Request builder

    private func request(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> URLRequest {
        let supabase = SupabaseManager.shared.client
        let accessToken: String
        do {
            accessToken = try await supabase.auth.session.accessToken
        } catch {
            throw APIError.notAuthenticated
        }

        var components = URLComponents(url: AppConfig.effectiveBaseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        if !queryItems.isEmpty { components.queryItems = queryItems }

        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            req.httpBody = try encoder.encode(body)
        }
        return req
    }

    // MARK: Core fetch

    func fetch<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        let req = try await request(path: path, method: method, body: body, queryItems: queryItems)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if http.statusCode == 409 {
            let err = try? JSONDecoder.api.decode(APIErrorResponse.self, from: data)
            if err?.error == "BOOK_LIMIT_REACHED" { throw APIError.bookLimitReached }
        }

        guard (200..<300).contains(http.statusCode) else {
            let msg = (try? JSONDecoder.api.decode(APIErrorResponse.self, from: data))?.error ?? "Unknown error"
            throw APIError.serverError(http.statusCode, msg)
        }

        do {
            return try JSONDecoder.api.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: Convenience methods

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        try await fetch(path, method: "GET", queryItems: queryItems)
    }

    func post<T: Decodable>(_ path: String, body: any Encodable) async throws -> T {
        try await fetch(path, method: "POST", body: body)
    }

    func patch<T: Decodable>(_ path: String, body: any Encodable) async throws -> T {
        try await fetch(path, method: "PATCH", body: body)
    }

    func put<T: Decodable>(_ path: String, body: any Encodable) async throws -> T {
        try await fetch(path, method: "PUT", body: body)
    }

    func delete(_ path: String) async throws {
        let req = try await request(path: path, method: "DELETE")
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError(0, "Delete failed")
        }
    }
}

// MARK: - Supabase singleton

final class SupabaseManager: @unchecked Sendable {
    static let shared = SupabaseManager()
    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }
}
