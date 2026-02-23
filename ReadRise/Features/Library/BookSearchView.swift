import SwiftUI

struct BookSearchView: View {
    let onAdd: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var vm = BookSearchViewModel()
    @State private var addedIds: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                if vm.isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if vm.results.isEmpty && !vm.query.isEmpty {
                    Text("No books found.")
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(vm.results) { volume in
                        BookSearchResultRow(
                            volume: volume,
                            isAdded: addedIds.contains(volume.id)
                        ) {
                            addedIds.insert(volume.id)
                            onAdd(volume.id)
                            dismiss()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $vm.query, prompt: "Search by title or author")
            .onChange(of: vm.query) { vm.search() }
            .navigationTitle("Add a Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct BookSearchResultRow: View {
    let volume: GoogleBooksVolume
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: volume.volumeInfo.imageLinks?.thumbnailURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color(hex: "#ddd5c8"))
            }
            .frame(width: 40, height: 60)
            .cornerRadius(5)
            .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(volume.volumeInfo.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                Text(volume.volumeInfo.authors?.joined(separator: ", ") ?? "Unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                onAdd()
            } label: {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isAdded ? Color.green : Color(hex: "#e8923a"))
            }
            .disabled(isAdded)
        }
        .padding(.vertical, 4)
    }
}
