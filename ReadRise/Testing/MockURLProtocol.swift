#if DEBUG
import Foundation

// MARK: - MockURLProtocol
// Intercepts all URLSession traffic when --uitesting is in launch arguments.
// Serves JSON fixtures bundled with the app (ReadRise/Testing/Fixtures/*.json).

final class MockURLProtocol: URLProtocol, @unchecked Sendable {

    override class func canInit(with request: URLRequest) -> Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path   = request.url?.path ?? ""
        let method = request.httpMethod ?? "GET"
        let (code, data) = MockFixtures.response(for: path, method: method)

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: code,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Fixture routing

enum MockFixtures {
    static func response(for path: String, method: String) -> (Int, Data) {
        switch (method, path) {
        // Stats & Goals
        case ("GET", "/api/stats"):
            return (200, fixture("stats"))
        case ("GET", "/api/goals"):
            return (200, fixture("goals"))
        case ("POST", "/api/goals"):
            return (200, fixture("goal_created"))

        // Library root
        case ("GET", "/api/library"):
            return (200, fixture("library"))
        case ("POST", "/api/library"):
            return (200, fixture("add_book_response"))

        // Specific user-book (PATCH / DELETE)
        case ("PATCH", let p) where p.matches(#"^/api/library/[^/]+$"#):
            return (200, fixture("add_book_response"))
        case ("DELETE", let p) where p.matches(#"^/api/library/[^/]+$"#):
            return (200, json(["data": NSNull()]))

        // Sessions
        case ("GET", let p) where p.matches(#"^/api/library/[^/]+/sessions$"#):
            return (200, fixture("sessions"))
        case ("POST", let p) where p.matches(#"^/api/library/[^/]+/sessions$"#):
            return (200, fixture("session_created"))
        case ("PATCH", let p) where p.matches(#"^/api/library/[^/]+/sessions/[^/]+$"#):
            return (200, fixture("session_ended"))

        // Progress
        case ("GET", let p) where p.matches(#"^/api/library/[^/]+/progress$"#):
            return (200, fixture("progress"))
        case ("POST", let p) where p.matches(#"^/api/library/[^/]+/progress$"#):
            return (200, fixture("progress_entry"))

        // Review
        case ("GET", let p) where p.matches(#"^/api/library/[^/]+/review$"#):
            return (200, fixture("review"))
        case ("PUT", let p) where p.matches(#"^/api/library/[^/]+/review$"#):
            return (200, fixture("review"))

        // Book search
        case ("GET", "/api/books/search"):
            return (200, fixture("search_results"))

        // User profile
        case ("GET", "/api/user/profile"):
            return (200, fixture("user_profile"))
        case ("PATCH", "/api/user/profile"):
            return (200, fixture("user_profile"))

        default:
            return (404, json(["error": "Mock: no fixture for \(method) \(path)"]))
        }
    }

    static func fixture(_ name: String) -> Data {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return json(["error": "Fixture '\(name).json' not found in bundle"])
        }
        return data
    }

    static func json(_ dict: [String: Any]) -> Data {
        (try? JSONSerialization.data(withJSONObject: dict)) ?? Data()
    }
}

private extension String {
    func matches(_ pattern: String) -> Bool {
        (try? NSRegularExpression(pattern: pattern)
            .firstMatch(in: self, range: NSRange(startIndex..., in: self))) != nil
    }
}
#endif
