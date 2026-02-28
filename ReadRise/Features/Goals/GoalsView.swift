import SwiftUI

struct GoalsView: View {
    @State private var vm = GoalsViewModel()
    @FocusState private var targetFocused: Bool

    private let months = ["J","F","M","A","M","J","J","A","S","O","N","D"]
    private let currentMonth = Calendar.current.component(.month, from: Date())
    private let yearStr = String(Calendar.current.component(.year, from: Date()))

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if vm.isLoading {
                        ProgressView().padding(.top, 40)
                    } else {
                        progressCard
                        if let bpm = vm.stats?.booksPerMonth, vm.booksRead > 0 {
                            barChart(booksPerMonth: bpm)
                        }
                        setGoalCard
                        presetButtons
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Color.rrBackground)
            .navigationTitle("Reading Goals")
            .refreshable { await vm.load(force: true) }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { targetFocused = false }
                }
            }
        }
        .task { await vm.load() }
    }

    // MARK: - Progress card

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(Color.rrAmber)
                Text("\(yearStr) Book Goal")
                    .font(.headline)
                    .foregroundStyle(Color.rrLabel)
            }

            if vm.goal != nil {
                HStack(alignment: .bottom) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(vm.booksRead)")
                            .font(.custom("Georgia", size: 40).bold())
                            .foregroundStyle(Color.rrLabel)
                        Text("/ \(vm.goalTarget)")
                            .font(.title3)
                            .foregroundStyle(Color.rrSecondaryLabel)
                    }
                    Spacer()
                    Text("\(Int(vm.percent * 100))%")
                        .font(.title2.bold())
                        .foregroundStyle(Color.rrSecondaryLabel)
                }

                ProgressBar(value: vm.percent)

                if let msg = vm.paceMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(Color.rrSecondaryLabel)
                }

                if vm.percent >= 1.0 {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                        Text("Goal complete — you've read \(vm.booksRead) books this year!")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.rrAmber)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.rrAmberTint)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundStyle(Color.rrFill)
                    Text("No goal set for \(yearStr)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.rrSecondaryLabel)
                    Text("Set a goal below to start tracking.")
                        .font(.caption)
                        .foregroundStyle(Color.rrSecondaryLabel)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding(16)
        .background(Color.rrCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.rrBorder, lineWidth: 0.5))
    }

    // MARK: - Bar chart

    private func barChart(booksPerMonth: [Int]) -> some View {
        let maxVal = max(booksPerMonth.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Books finished by month")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.rrLabel)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<12, id: \.self) { i in
                    let count = i < booksPerMonth.count ? booksPerMonth[i] : 0
                    let isFuture = i + 1 > currentMonth
                    VStack(spacing: 2) {
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.rrSecondaryLabel)
                        }
                        Rectangle()
                            .fill(isFuture ? Color.rrBorder : (count > 0 ? Color.rrAmber : Color.rrParchment))
                            .frame(height: max(CGFloat(count) / CGFloat(maxVal) * 60, 4))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                        Text(months[i])
                            .font(.system(size: 9))
                            .foregroundStyle(Color.rrSecondaryLabel)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 88)
        }
        .padding(16)
        .background(Color.rrCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.rrBorder, lineWidth: 0.5))
    }

    // MARK: - Set goal card

    private var setGoalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(vm.goal != nil ? "Update goal" : "Set a goal")
                .font(.headline)
                .foregroundStyle(Color.rrLabel)
            Text("How many books in \(yearStr)?")
                .font(.caption)
                .foregroundStyle(Color.rrSecondaryLabel)

            if let err = vm.errorMessage {
                Text(err).font(.caption).foregroundStyle(.red)
            }

            HStack(spacing: 8) {
                TextField("e.g. 24", text: $vm.targetText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($targetFocused)
                    .accessibilityIdentifier("goals.targetField")
                Button(vm.goal != nil ? "Update" : "Set goal") {
                    Haptic.success()
                    Task { await vm.save() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.rrAmber)
                .disabled(vm.isSaving || vm.targetText.isEmpty)
                .accessibilityIdentifier("goals.saveGoal")
            }
        }
        .padding(16)
        .background(Color.rrCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.rrBorder, lineWidth: 0.5))
    }

    // MARK: - Presets

    private var presetButtons: some View {
        HStack(spacing: 8) {
            ForEach([12, 24, 36, 52], id: \.self) { n in
                Button("\(n) books") {
                    vm.targetText = "\(n)"
                    Haptic.impact(.light)
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(vm.targetText == "\(n)" ? Color.rrAmber : Color.rrCard)
                .foregroundStyle(vm.targetText == "\(n)" ? Color.white : Color.rrLabel)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.rrBorder, lineWidth: 0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
