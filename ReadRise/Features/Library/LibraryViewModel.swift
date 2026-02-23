import Foundation

@Observable
@MainActor
final class LibraryViewModel {
    var nowReading: [UserBook] = []
    var wantToRead: [UserBook] = []
    var finished: [UserBook] = []
    var abandoned: [UserBook] = []
    var isLoading = true
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let resp: APIResponse<[UserBook]> = try await APIClient.shared.get("/api/library")
            let all = resp.data
            nowReading = all.filter { $0.shelf == "reading" }
            wantToRead = all.filter { $0.shelf == "want_to_read" }
            finished   = all.filter { $0.shelf == "finished" }
            abandoned  = all.filter { $0.shelf == "abandoned" }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addBook(volumeId: String, shelf: String = "reading") async throws {
        struct AddBody: Encodable {
            let volumeId: String
            let shelf: String
            let format: String
        }
        let _: APIResponse<UserBook> = try await APIClient.shared.post(
            "/api/library",
            body: AddBody(volumeId: volumeId, shelf: shelf, format: "physical")
        )
        await load()
    }
}
