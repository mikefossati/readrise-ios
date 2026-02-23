import SwiftUI

struct BookDetailView: View {
    @State var vm: BookDetailViewModel
    @State private var showShelfPicker = false
    @Environment(\.dismiss) private var dismiss

    init(userBook: UserBook) {
        _vm = State(initialValue: BookDetailViewModel(userBook: userBook))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                bookHeader
                sessionCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                if vm.userBook.shelf != "finished" && vm.userBook.shelf != "abandoned" {
                    progressSection
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                if !vm.completedSessions.isEmpty {
                    sessionHistorySection
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                reviewSection
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
            }
        }
        .background(Color(hex: "#faf8f4"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Book header (parchment bg)

    private var bookHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: vm.userBook.book.coverURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color(hex: "#ddd5c8"))
            }
            .frame(width: 90, height: 134)
            .cornerRadius(8)
            .clipped()
            .shadow(radius: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(vm.userBook.book.title)
                    .font(.custom("Georgia", size: 18).bold())
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                    .lineLimit(3)

                if let subtitle = vm.userBook.book.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#7a7068"))
                        .lineLimit(2)
                }

                Text(vm.userBook.book.firstAuthor)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "#7a7068"))

                if let pages = vm.userBook.book.pageCount {
                    Text("\(pages) pages")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#7a7068"))
                }

                // Shelf picker
                Button {
                    showShelfPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(vm.userBook.shelfLabel)
                            .font(.caption.weight(.medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#ddd5c8"), lineWidth: 1))
                    .foregroundStyle(Color(hex: "#1a1a2e"))
                }
                .confirmationDialog("Move to shelf", isPresented: $showShelfPicker) {
                    ForEach(["reading", "want_to_read", "finished", "abandoned"], id: \.self) { shelf in
                        Button(shelf.replacingOccurrences(of: "_", with: " ").capitalized) {
                            Task { await vm.changeShelf(to: shelf) }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#f0ebe0"))
    }

    // MARK: - Session card (amber tint)

    private var sessionCard: some View {
        VStack(spacing: 10) {
            if let active = vm.activeSession {
                // Active session
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(Color(hex: "#e8923a"))
                    Text(TimerService.shared.activeSessionId == active.id
                         ? TimerService.shared.formattedElapsed
                         : "Session active")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(Color(hex: "#1a1a2e"))
                    Spacer()
                }

                HStack(spacing: 8) {
                    TextField("End page", text: $vm.endPageText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)

                    Button {
                        Task { await vm.endSession() }
                    } label: {
                        Label("End session", systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#e8923a"))
                    .disabled(vm.isEndingSession)
                }
            } else if vm.userBook.shelf != "abandoned" {
                // No active session
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(Color(hex: "#e8923a"))
                    Text("Ready to read?")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "#1a1a2e"))
                    Spacer()
                    Button {
                        Task { await vm.startSession() }
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#e8923a"))
                    .disabled(vm.isStartingSession)
                }
            }
        }
        .padding(14)
        .background(Color(hex: "#fef3e2"))
        .cornerRadius(14)
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let prog = vm.progress, let page = vm.latestProgress?.page, let total = vm.userBook.book.pageCount {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("p. \(page) / \(total)")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#7a7068"))
                    }
                    ProgressView(value: prog)
                        .tint(Color(hex: "#e8923a"))
                }
            }

            HStack(spacing: 8) {
                TextField("Current page", text: $vm.newPageText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Button("Log") {
                    Task { await vm.saveProgress() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#e8923a"))
                .disabled(vm.isSavingProgress || vm.newPageText.isEmpty)
            }
        }
    }

    // MARK: - Session history

    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session history")
                .font(.subheadline.weight(.medium))

            ForEach(vm.completedSessions) { s in
                HStack {
                    Text(s.startedAt.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#7a7068"))
                    Spacer()
                    Text(s.formattedDuration)
                        .font(.caption.monospacedDigit())
                    if let p = s.pagesRead {
                        Text("\(p) pages")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#7a7068"))
                    }
                    if let pph = s.pagesPerHour {
                        Text("\(Int(pph)) p/hr")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#7a7068"))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.6))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Review

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rating & notes")
                .font(.subheadline.weight(.medium))

            // Star rating
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: Double(star) <= vm.reviewRating ? "star.fill" : "star")
                        .foregroundStyle(Color(hex: "#e8923a"))
                        .onTapGesture { vm.reviewRating = Double(star) }
                }
                if vm.reviewRating > 0 {
                    Button("Clear") { vm.reviewRating = 0 }
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#7a7068"))
                }
            }

            TextEditor(text: $vm.reviewBody)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#ddd5c8")))

            Button("Save") {
                Task { await vm.saveReview() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#e8923a"))
            .disabled(vm.isSavingReview)
        }
    }
}
