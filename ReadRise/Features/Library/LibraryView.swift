import SwiftUI

struct LibraryView: View {
    @State private var vm = LibraryViewModel()
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var showBarcode = false
    @State private var selectedBook: UserBook?
    @State private var bookLimitAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if vm.isLoading {
                        ProgressView().padding(.top, 40)
                    } else {
                        if let error = vm.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(Color.rrSecondaryLabel)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        if !vm.nowReading.isEmpty {
                            nowReadingBand
                        }
                        shelfSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.rrBackground)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button { showBarcode = true } label: {
                            Image(systemName: "barcode.viewfinder")
                        }
                        Button { showSearch = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                    .foregroundStyle(Color.rrAmber)
                }
            }
            .refreshable { await vm.load() }
            .sheet(isPresented: $showSearch) {
                BookSearchView { volumeId in
                    Task {
                        do {
                            try await vm.addBook(volumeId: volumeId)
                            Haptic.success()
                        } catch APIError.bookLimitReached {
                            bookLimitAlert = true
                        } catch {}
                    }
                }
            }
            .sheet(isPresented: $showBarcode) {
                BarcodeScanView { volumeId in
                    Task {
                        do {
                            try await vm.addBook(volumeId: volumeId)
                            Haptic.success()
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
                .foregroundStyle(Color.rrSecondaryLabel)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.nowReading) { book in
                        Button {
                            Haptic.impact(.light)
                            selectedBook = book
                        } label: {
                            NowReadingCard(userBook: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Shelf section — native segmented Picker

    private var shelfSection: some View {
        VStack(spacing: 14) {
            Picker("Shelf", selection: $selectedTab) {
                Text("To Read").tag(0)
                Text("Finished").tag(1)
                Text("Abandoned").tag(2)
            }
            .pickerStyle(.segmented)

            let books = [vm.wantToRead, vm.finished, vm.abandoned][selectedTab]

            if books.isEmpty {
                emptyShelf(index: selectedTab)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                    spacing: 12
                ) {
                    ForEach(books) { book in
                        Button {
                            Haptic.impact(.light)
                            selectedBook = book
                        } label: {
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
                .foregroundStyle(Color.rrFill)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.rrSecondaryLabel)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.rrSecondaryLabel)
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
                Rectangle().fill(Color.rrFill)
            }
            .frame(width: 56, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(userBook.book.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(Color.rrLabel)
                Text(userBook.book.firstAuthor)
                    .font(.caption)
                    .foregroundStyle(Color.rrSecondaryLabel)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill").font(.caption)
                    Text("Continue").font(.caption.weight(.medium))
                }
                .foregroundStyle(Color.rrAmber)
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.rrCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.rrBorder, lineWidth: 0.5))
        .frame(width: 220)
    }
}

// MARK: - Shelf cover card

private struct ShelfCoverCard: View {
    let userBook: UserBook

    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: userBook.book.coverURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.rrFill)
                    .overlay(
                        Text(userBook.book.title)
                            .font(.system(size: 9))
                            .foregroundStyle(Color.rrSecondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(4)
                    )
            }
            .aspectRatio(2/3, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(userBook.book.title)
                .font(.system(size: 11).weight(.medium))
                .lineLimit(2)
                .foregroundStyle(Color.rrLabel)
                .multilineTextAlignment(.center)
        }
    }
}
