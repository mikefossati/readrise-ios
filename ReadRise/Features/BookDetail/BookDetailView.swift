import Kingfisher
import SwiftUI

struct BookDetailView: View {
    @State var vm: BookDetailViewModel
    @State private var showShelfPicker = false
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Bool

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

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        if vm.isDeletingBook {
                            ProgressView().tint(.red)
                        } else {
                            Image(systemName: "trash")
                            Text("Remove from library")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)
                .disabled(vm.isDeletingBook)
                .accessibilityIdentifier("bookDetail.deleteBook")
                .confirmationDialog(
                    "Remove \"\(vm.userBook.book.title)\" from your library?",
                    isPresented: $showDeleteConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Remove", role: .destructive) {
                        Task { await vm.deleteBook() }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color.rrBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = false }
            }
        }
        .onChange(of: vm.wasDeleted) { _, deleted in
            if deleted { dismiss() }
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Book header

    private var bookHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            KFImage(vm.userBook.book.coverURL)
                .placeholder { Rectangle().fill(Color.rrFill) }
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 134)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(vm.userBook.book.title)
                    .font(.custom("Georgia", size: 18).bold())
                    .foregroundStyle(Color.rrLabel)
                    .lineLimit(3)

                if let subtitle = vm.userBook.book.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.rrSecondaryLabel)
                        .lineLimit(2)
                }

                Text(vm.userBook.book.firstAuthor)
                    .font(.subheadline)
                    .foregroundStyle(Color.rrSecondaryLabel)

                if let pages = vm.userBook.book.pageCount {
                    Text("\(pages) pages")
                        .font(.caption)
                        .foregroundStyle(Color.rrSecondaryLabel)
                }

                Button {
                    Haptic.impact(.light)
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
                    .background(Color.rrCard)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.rrBorder, lineWidth: 1))
                    .foregroundStyle(Color.rrLabel)
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
        .background(Color.rrParchment)
    }

    // MARK: - Session card

    private var sessionCard: some View {
        VStack(spacing: 10) {
            if let active = vm.activeSession {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(Color.rrAmber)
                    if TimerService.shared.activeSessionId == active.id {
                        TimelineView(.periodic(from: .now, by: 1)) { _ in
                            Text(TimerService.shared.formattedElapsed)
                                .font(.title3.bold().monospacedDigit())
                                .foregroundStyle(Color.rrLabel)
                        }
                    } else {
                        Text("Session active")
                            .font(.title3.bold())
                            .foregroundStyle(Color.rrLabel)
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    TextField("End page", text: $vm.endPageText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .focused($focusedField)
                        .accessibilityIdentifier("bookDetail.endPageField")

                    Button {
                        Haptic.success()
                        Task { await vm.endSession() }
                    } label: {
                        Label("End session", systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.rrAmber)
                    .disabled(vm.isEndingSession)
                    .accessibilityIdentifier("bookDetail.endSession")
                }
            } else if vm.userBook.shelf != "abandoned" {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(Color.rrAmber)
                    Text("Ready to read?")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.rrLabel)
                    Spacer()
                    Button {
                        Haptic.impact(.medium)
                        Task { await vm.startSession() }
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.rrAmber)
                    .disabled(vm.isStartingSession)
                    .accessibilityIdentifier("bookDetail.startSession")
                }
            }
        }
        .padding(14)
        .background(Color.rrAmberTint)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let prog = vm.progress, let page = vm.latestProgress?.page, let total = vm.userBook.book.pageCount {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.rrLabel)
                        Spacer()
                        Text("p. \(page) / \(total)")
                            .font(.caption)
                            .foregroundStyle(Color.rrSecondaryLabel)
                    }
                    ProgressBar(value: prog)
                }
            }

            HStack(spacing: 8) {
                TextField("Current page", text: $vm.newPageText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField)
                    .accessibilityIdentifier("bookDetail.progressField")
                Button("Log") {
                    Haptic.impact(.light)
                    Task { await vm.saveProgress() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.rrAmber)
                .disabled(vm.isSavingProgress || vm.newPageText.isEmpty)
                .accessibilityIdentifier("bookDetail.logProgress")
            }
        }
    }

    // MARK: - Session history

    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session history")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.rrLabel)

            ForEach(vm.completedSessions) { s in
                HStack {
                    Text(s.startedAt.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption)
                        .foregroundStyle(Color.rrSecondaryLabel)
                    Spacer()
                    Text(s.formattedDuration)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.rrLabel)
                    if let p = s.pagesRead {
                        Text("\(p) pages")
                            .font(.caption)
                            .foregroundStyle(Color.rrSecondaryLabel)
                    }
                    if let pph = s.pagesPerHour {
                        Text("\(Int(pph)) p/hr")
                            .font(.caption)
                            .foregroundStyle(Color.rrSecondaryLabel)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.rrCard)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Review

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rating & notes")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.rrLabel)

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        vm.reviewRating = Double(star)
                        Haptic.impact(.light)
                    } label: {
                        Image(systemName: Double(star) <= vm.reviewRating ? "star.fill" : "star")
                            .foregroundStyle(Color.rrAmber)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                }
                if vm.reviewRating > 0 {
                    Button("Clear") {
                        vm.reviewRating = 0
                        Haptic.impact(.light)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.rrSecondaryLabel)
                }
            }

            TextEditor(text: $vm.reviewBody)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color.rrCard)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.rrBorder))
                .accessibilityIdentifier("bookDetail.reviewBody")

            Text("\(vm.reviewBody.count) / 1000")
                .font(.caption2)
                .foregroundStyle(vm.reviewBody.count > 1000 ? .red : Color.rrSecondaryLabel)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Button("Save") {
                Haptic.success()
                Task { await vm.saveReview() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.rrAmber)
            .disabled(vm.isSavingReview || vm.reviewRating == 0)
            .accessibilityIdentifier("bookDetail.saveReview")
        }
    }
}
