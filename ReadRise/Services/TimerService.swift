import Foundation
import SwiftUI
import UIKit

private let kTimerStartedAt = "rr_timer_started_at"
private let kTimerSessionId = "rr_timer_session_id"
private let kTimerUserBookId = "rr_timer_user_book_id"

@Observable
@MainActor
final class TimerService {
    static let shared = TimerService()

    // Public state
    var isRunning = false
    var elapsedSeconds: Int = 0
    var activeSessionId: String?
    var activeUserBookId: String?

    private var startedAt: Date?
    private var displayTimer: Timer?

    private init() {
        restoreFromBackground()
        registerTerminationObserver()
    }

    // MARK: - Start

    func start(sessionId: String, userBookId: String, startedAt: Date) {
        self.startedAt = startedAt
        self.activeSessionId = sessionId
        self.activeUserBookId = userBookId
        self.isRunning = true

        // Persist across app restart / background
        UserDefaults.standard.set(startedAt.timeIntervalSinceReferenceDate, forKey: kTimerStartedAt)
        UserDefaults.standard.set(sessionId, forKey: kTimerSessionId)
        UserDefaults.standard.set(userBookId, forKey: kTimerUserBookId)

        startDisplayTimer()
    }

    // MARK: - Stop

    func stop() {
        isRunning = false
        startedAt = nil
        activeSessionId = nil
        activeUserBookId = nil
        elapsedSeconds = 0
        displayTimer?.invalidate()
        displayTimer = nil

        UserDefaults.standard.removeObject(forKey: kTimerStartedAt)
        UserDefaults.standard.removeObject(forKey: kTimerSessionId)
        UserDefaults.standard.removeObject(forKey: kTimerUserBookId)
    }

    // MARK: - Foreground refresh

    /// Call when app returns to foreground to re-sync elapsed time
    func refreshFromForeground() {
        guard isRunning, let start = startedAt else { return }
        elapsedSeconds = Int(Date().timeIntervalSince(start))
    }

    // MARK: - Background restore

    private func restoreFromBackground() {
        guard
            let startInterval = UserDefaults.standard.object(forKey: kTimerStartedAt) as? TimeInterval,
            let sessionId = UserDefaults.standard.string(forKey: kTimerSessionId),
            let userBookId = UserDefaults.standard.string(forKey: kTimerUserBookId)
        else { return }

        let start = Date(timeIntervalSinceReferenceDate: startInterval)
        let elapsed = Int(Date().timeIntervalSince(start))

        // Discard sessions older than 8 hours — likely orphaned from a crash
        if elapsed > 8 * 3600 {
            UserDefaults.standard.removeObject(forKey: kTimerStartedAt)
            UserDefaults.standard.removeObject(forKey: kTimerSessionId)
            UserDefaults.standard.removeObject(forKey: kTimerUserBookId)
            return
        }

        self.startedAt = start
        self.activeSessionId = sessionId
        self.activeUserBookId = userBookId
        self.isRunning = true
        self.elapsedSeconds = elapsed
        startDisplayTimer()
    }

    // MARK: - Termination observer

    private func registerTerminationObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.isRunning, let sessionId = self.activeSessionId else { return }
            Task {
                struct StopBody: Encodable { let sessionId: String }
                try? await APIClient.shared.put("/api/timer/stop", body: StopBody(sessionId: sessionId))
                await MainActor.run { self.stop() }
            }
        }
    }

    // MARK: - Display timer (updates elapsedSeconds every second)

    private func startDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.startedAt else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }
    }

    // MARK: - Formatting

    var formattedElapsed: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
