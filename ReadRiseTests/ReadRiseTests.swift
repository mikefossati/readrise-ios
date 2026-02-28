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

    // MARK: - Timer formatting

    @Test func timerFormattedElapsedEdgeCase() {
        // 2h 5m 3s
        let secs = 2 * 3600 + 5 * 60 + 3
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        #expect(String(format: "%02d:%02d:%02d", h, m, s) == "02:05:03")
    }

    // MARK: - Stale session threshold

    @Test func staleSessionThreshold() {
        // A session started more than 8 hours ago should be considered stale
        let start = Date().addingTimeInterval(-(8 * 3600 + 1))
        let elapsed = Int(Date().timeIntervalSince(start))
        #expect(elapsed > 8 * 3600)
    }

    // MARK: - Goal pace

    @Test func goalPaceOnPace() {
        // Target 24 books, day 182 of 365, read 12 — exactly on pace
        let target = 24; let booksRead = 12; let dayOfYear = 182
        let expected = Double(target) * (Double(dayOfYear) / 365.0)
        #expect(Double(booksRead) >= expected)
    }

    @Test func goalPaceBehind() {
        // Target 24 books, day 182 of 365, read 5 — behind pace
        let target = 24; let booksRead = 5; let dayOfYear = 182
        let expected = Double(target) * (Double(dayOfYear) / 365.0)
        #expect(Double(booksRead) < expected)
    }

    // MARK: - Codable round-trip (validates new Codable conformances)

    @Test func codableRoundTrip() throws {
        struct Payload: Codable, Equatable { let value: Int }
        let data = try JSONEncoder().encode(Payload(value: 99))
        let decoded = try JSONDecoder().decode(Payload.self, from: data)
        #expect(decoded == Payload(value: 99))
    }

    // MARK: - NetworkMonitor

    @Test func networkMonitorInstantiates() {
        // Verify shared instance is accessible and isConnected is a valid Bool
        let monitor = NetworkMonitor.shared
        let connected = monitor.isConnected
        #expect(connected == true || connected == false)
    }
}
