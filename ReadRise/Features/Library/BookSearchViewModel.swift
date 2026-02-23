import Foundation

@Observable
@MainActor
final class BookSearchViewModel {
    var query = ""
    var results: [GoogleBooksVolume] = []
    var isSearching = false
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    func search() {
        searchTask?.cancel()
        guard query.trimmingCharacters(in: .whitespaces).count >= 2 else {
            results = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            isSearching = true
            errorMessage = nil
            do {
                let resp: APIResponse<[GoogleBooksVolume]> = try await APIClient.shared.get(
                    "/api/books/search",
                    queryItems: [URLQueryItem(name: "q", value: query)]
                )
                results = resp.data
            } catch {
                if !(error is CancellationError) {
                    errorMessage = error.localizedDescription
                }
            }
            isSearching = false
        }
    }
}
