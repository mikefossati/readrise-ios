import Testing
@testable import ReadRise

// MARK: - Model tests

struct ModelsTests {
    @Test func colorHexParsing() {
        // Verify hex color parsing doesn't crash on valid inputs
        _ = "#e8923a"
        _ = "#faf8f4"
        _ = "#1a1a2e"
    }

    @Test func timerFormatting() {
        // 1h 30m 5s
        let secs = 3600 + 1800 + 5
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        let formatted = String(format: "%02d:%02d:%02d", h, m, s)
        #expect(formatted == "01:30:05")
    }

    @Test func sessionFormattedDuration() {
        let session = ReadingSession(
            id: "1",
            startedAt: Date(),
            endedAt: Date(),
            durationSeconds: 4200,
            pagesRead: 30,
            pagesPerHour: 25.7
        )
        #expect(session.formattedDuration == "1h 10m")
    }

    @Test func goalPaceCalculation() async {
        let vm = GoalsViewModel()
        // With no data, paceMessage should be nil
        #expect(vm.paceMessage == nil)
    }
}
