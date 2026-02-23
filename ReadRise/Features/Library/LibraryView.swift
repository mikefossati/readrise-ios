import SwiftUI

struct LibraryView: View {
    @State private var vm = LibraryViewModel()
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var showBarcode = false
    @State private var selectedBook: UserBook?
    @State private var bookLimitAlert = false

    private let tabs = ["Want to Read", "Finished", "Abandoned"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if vm.isLoading {
                        ProgressView().padding(.top, 40)
                    } else {
                        // Now Reading band
                        if !vm.nowReading.isEmpty {
                            nowReadingBand
                        }
                        // Shelf tabs
                        shelfSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(hex: "#faf8f4"))
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button {
                            showBarcode = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                        }
                        Button {
                            showSearch = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    .foregroundStyle(Color(hex: "#e8923a"))
                }
            }
            .refreshable { await vm.load() }
            .sheet(isPresented: $showSearch) {
                BookSearchView { volumeId in
                    Task {
                        do {
                            try await vm.addBook(volumeId: volumeId)
                        } catch APIError.bookLimitReached {
                            bookLimitAlert = true
                        } catch {
                            // handled in vm
                        }
                    }
                }
            }
            .sheet(isPresented: $showBarcode) {
                BarcodeScanView { volumeId in
                    Task {
                        do {
                            try await vm.addBook(volumeId: volumeId)
                        } catch APIError.bookLimitReached {
                            bookLimitAlert = true
                        } catch {}
                    }
                }
            }
            .navigationDestination(item: $selectedBook) { book in
                BookDetailView(userBook: book)
            }
            .alert("Book Limit Reached", isPresented: $bookLimitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You've reached the 50-book limit on the Free plan. Visit readrise.app to upgrade.")
            }
        }
        .task { await vm.load() }
    }

    // MARK: - Now Reading band

    private var nowReadingBand: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Now Reading")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(hex: "#7a7068"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.nowReading) { book in
                        Button { selectedBook = book } label: {
                            NowReadingCard(userBook: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Shelf tabs

    private var shelfSection: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { i in
                    Button {
                        selectedTab = i
                    } label: {
                        VStack(spacing: 4) {
                            Text(tabs[i])
                                .font(.subheadline.weight(selectedTab == i ? .semibold : .regular))
                                .foregroundStyle(selectedTab == i ? Color(hex: "#e8923a") : Color(hex: "#7a7068"))
                            Rectangle()
                                .fill(selectedTab == i ? Color(hex: "#e8923a") : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 12)

            // Grid for selected tab
            let books = [vm.wantToRead, vm.finished, vm.abandoned][selectedTab]

            if books.isEmpty {
                emptyShelf(index: selectedTab)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 12) {
                    ForEach(books) { book in
                        Button { selectedBook = book } label: {
                            ShelfCoverCard(userBook: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func emptyShelf(index: Int) -> some View {
        let messages = [
            ("Your reading queue is empty", "Search for books or scan a barcode to add them."),
            ("No finished books yet", "Books you mark as finished will appear here."),
            ("No abandoned books", "Books you've set aside will appear here.")
        ]
        let (title, subtitle) = messages[index]
        return VStack(spacing: 8) {
            Image(systemName: "books.vertical")
                .font(.largeTitle)
                .foregroundStyle(Color(hex: "#ddd5c8"))
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(hex: "#7a7068"))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color(hex: "#7a7068"))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 48)
    }
}

// MARK: - Now Reading card

private struct NowReadingCard: View {
    let userBook: UserBook

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: userBook.book.coverURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color(hex: "#ddd5c8"))
            }
            .frame(width: 56, height: 84)
            .cornerRadius(6)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(userBook.book.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                Text(userBook.book.firstAuthor)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#7a7068"))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                    Text("Continue")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(Color(hex: "#e8923a"))
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ddd5c8"), lineWidth: 0.5))
        .frame(width: 220)
    }
}

// MARK: - Shelf cover card (grid item)

private struct ShelfCoverCard: View {
    let userBook: UserBook

    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: userBook.book.coverURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color(hex: "#ddd5c8"))
                    .overlay(
                        Text(userBook.book.title)
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: "#7a7068"))
                            .multilineTextAlignment(.center)
                            .padding(4)
                    )
            }
            .aspectRatio(2/3, contentMode: .fill)
            .cornerRadius(8)
            .clipped()

            Text(userBook.book.title)
                .font(.system(size: 11).weight(.medium))
                .lineLimit(2)
                .foregroundStyle(Color(hex: "#1a1a2e"))
                .multilineTextAlignment(.center)
        }
    }
}
