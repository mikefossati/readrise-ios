import Foundation

// MARK: - API wrapper

struct APIResponse<T: Decodable>: Decodable {
    let data: T
}

struct APIErrorResponse: Decodable {
    let error: String
}

// MARK: - Book & Library

struct Book: Decodable, Identifiable, Hashable, Sendable {
    static func == (lhs: Book, rhs: Book) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: String
    let title: String
    let authors: [String]
    let coverUrl: String?
    let pageCount: Int?
    let genres: [String]
    let subtitle: String?
    let publisher: String?
    let publishedDate: String?
    let language: String?

    var firstAuthor: String { authors.first ?? "" }
    var coverURL: URL? { coverUrl.flatMap(URL.init) }
}

struct UserBook: Decodable, Identifiable, Hashable, Sendable {
    static func == (lhs: UserBook, rhs: UserBook) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: String
    let shelf: String
    let format: String
    let bookId: String
    let updatedAt: Date
    let finishedAt: Date?
    let startedAt: Date?
    let abandonedAt: Date?
    let book: Book

    var shelfLabel: String {
        switch shelf {
        case "reading": "Reading"
        case "want_to_read": "Want to Read"
        case "finished": "Finished"
        case "abandoned": "Abandoned"
        default: shelf
        }
    }
}

// MARK: - Progress

struct ProgressEntry: Decodable, Identifiable, Sendable {
    let id: String
    let page: Int
    let loggedAt: Date
    let note: String?
}

// MARK: - Sessions

struct ReadingSession: Decodable, Identifiable, Sendable {
    let id: String
    let startedAt: Date
    let endedAt: Date?
    let durationSeconds: Int?
    let pagesRead: Int?
    let pagesPerHour: Double?

    var isActive: Bool { endedAt == nil }

    var formattedDuration: String {
        guard let secs = durationSeconds else { return "—" }
        let h = secs / 3600
        let m = (secs % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

// MARK: - Goals

struct Goal: Decodable, Identifiable, Sendable {
    let id: String
    let year: Int
    let goalType: String
    let target: Int
    let createdAt: Date
}

// MARK: - Stats

struct Stats: Decodable, Sendable {
    let booksReadThisYear: Int
    let totalPagesAllTime: Int
    let totalPagesThisYear: Int
    let totalHoursAllTime: Int
    let averagePagesPerHour: Int?
    let booksPerMonth: [Int]
    let streak: StreakData
}

struct StreakData: Decodable, Sendable {
    let currentStreak: Int
    let longestStreak: Int
    let lastActiveDate: String?
}

// MARK: - User Profile

struct UserProfile: Decodable, Sendable {
    let displayName: String?
    let avatarUrl: String?
}

struct UserPlan: Decodable, Sendable {
    let subscriptionTier: String
    let subscriptionStatus: String?
}

// MARK: - Google Books (for search results)

struct GoogleBooksVolume: Decodable, Identifiable, Sendable {
    let id: String
    let volumeInfo: VolumeInfo

    struct VolumeInfo: Decodable, Sendable {
        let title: String
        let authors: [String]?
        let imageLinks: ImageLinks?
        let pageCount: Int?
        let categories: [String]?
        let subtitle: String?
        let publisher: String?
        let publishedDate: String?
        let language: String?

        struct ImageLinks: Decodable, Sendable {
            let thumbnail: String?
            var thumbnailURL: URL? {
                thumbnail
                    .map { $0.replacingOccurrences(of: "http://", with: "https://") }
                    .flatMap(URL.init)
            }
        }
    }

    var displayTitle: String { volumeInfo.title }
    var displayAuthors: String { volumeInfo.authors?.joined(separator: ", ") ?? "" }
}

// MARK: - JSON Decoder

extension JSONDecoder {
    nonisolated(unsafe) private static let _isoFull: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    nonisolated(unsafe) private static let _isoBasic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    // Handles PostgreSQL `date` columns (no time component) — postgres-js
    // returns these as "YYYY-MM-DD" strings, not full ISO 8601 timestamps.
    private static let _dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    static let api: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = _isoFull.date(from: string) { return date }
            if let date = _isoBasic.date(from: string) { return date }
            if let date = _dateOnly.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return decoder
    }()
}
