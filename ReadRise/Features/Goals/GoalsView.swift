import SwiftUI

struct GoalsView: View {
    @State private var vm = GoalsViewModel()
    @FocusState private var targetFocused: Bool

    private let months = ["J","F","M","A","M","J","J","A","S","O","N","D"]
    private let currentMonth = Calendar.current.component(.month, from: Date())

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
            .background(Color(hex: "#faf8f4"))
            .navigationTitle("Reading Goals")
            .refreshable { await vm.load() }
        }
        .task { await vm.load() }
    }

    // MARK: - Progress card

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(Color(hex: "#e8923a"))
                Text("\(Calendar.current.component(.year, from: Date())) Book Goal")
                    .font(.headline)
            }

            if vm.goal != nil {
                HStack(alignment: .bottom) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(vm.booksRead)")
                            .font(.custom("Georgia", size: 40).bold())
                            .foregroundStyle(Color(hex: "#1a1a2e"))
                        Text("/ \(vm.goalTarget)")
                            .font(.title3)
                            .foregroundStyle(Color(hex: "#7a7068"))
                    }
                    Spacer()
                    Text("\(Int(vm.percent * 100))%")
                        .font(.title2.bold())
                        .foregroundStyle(Color(hex: "#7a7068"))
                }

                ProgressView(value: vm.percent)
                    .tint(Color(hex: "#e8923a"))
                    .scaleEffect(x: 1, y: 2)

                if let msg = vm.paceMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#7a7068"))
                }

                if vm.percent >= 1.0 {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                        Text("Goal complete — you've read \(vm.booksRead) books this year!")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(hex: "#e8923a"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#fef3e2"))
                    .cornerRadius(8)
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundStyle(Color(hex: "#ddd5c8"))
                    Text("No goal set for \(Calendar.current.component(.year, from: Date()))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "#7a7068"))
                    Text("Set a goal below to start tracking.")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#7a7068"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ddd5c8"), lineWidth: 0.5))
    }

    // MARK: - Bar chart

    private func barChart(booksPerMonth: [Int]) -> some View {
        let maxVal = max(booksPerMonth.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Books finished by month")
                .font(.subheadline.weight(.medium))

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<12, id: \.self) { i in
                    let count = i < booksPerMonth.count ? booksPerMonth[i] : 0
                    let isFuture = i + 1 > currentMonth
                    VStack(spacing: 2) {
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: "#7a7068"))
                        }
                        Rectangle()
                            .fill(isFuture ? Color(hex: "#ddd5c8") : (count > 0 ? Color(hex: "#e8923a") : Color(hex: "#f0ebe0")))
                            .frame(height: max(CGFloat(count) / CGFloat(maxVal) * 60, 4))
                            .cornerRadius(3)
                        Text(months[i])
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: "#7a7068"))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 88)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ddd5c8"), lineWidth: 0.5))
    }

    // MARK: - Set goal card

    private var setGoalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(vm.goal != nil ? "Update goal" : "Set a goal")
                .font(.headline)
            Text("How many books in \(Calendar.current.component(.year, from: Date()))?")
                .font(.caption)
                .foregroundStyle(Color(hex: "#7a7068"))

            if let err = vm.errorMessage {
                Text(err).font(.caption).foregroundStyle(.red)
            }

            HStack(spacing: 8) {
                TextField("e.g. 24", text: $vm.targetText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($targetFocused)
                Button(vm.goal != nil ? "Update" : "Set goal") {
                    Task { await vm.save() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#e8923a"))
                .disabled(vm.isSaving || vm.targetText.isEmpty)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ddd5c8"), lineWidth: 0.5))
    }

    // MARK: - Presets

    private var presetButtons: some View {
        HStack(spacing: 8) {
            ForEach([12, 24, 36, 52], id: \.self) { n in
                Button("\(n) books") {
                    vm.targetText = "\(n)"
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(vm.targetText == "\(n)" ? Color(hex: "#e8923a") : Color.white)
                .foregroundStyle(vm.targetText == "\(n)" ? Color.white : Color(hex: "#1a1a2e"))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#ddd5c8"), lineWidth: 0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
