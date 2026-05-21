import SwiftUI
import Combine

class FocusTimerViewModel: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var timeRemaining: Int = 25 * 60
    @Published var totalTime: Int = 25 * 60
    @Published var currentBlockName: String = "Focus Session"
    @Published var currentCategory: BlockCategory = .work
    @Published var sessions: [FocusSession] = [] {
        didSet { saveSessions() }
    }
    @Published var showCompletionCelebration: Bool = false
    @Published var selectedMinutes: Int = 25

    private var timer: Timer?
    private let sessionsKey = "focus_sessions"

    init() {
        loadSessions()
    }

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }

    var timeString: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    var totalFocusMinutesToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) && $0.isCompleted }
            .reduce(0) { $0 + $1.actualMinutes }
    }

    var completedSessionsToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions.filter { Calendar.current.isDate($0.date, inSameDayAs: today) && $0.isCompleted }.count
    }

    func start(blockName: String, category: BlockCategory, minutes: Int) {
        currentBlockName = blockName
        currentCategory = category
        totalTime = minutes * 60
        timeRemaining = totalTime
        selectedMinutes = minutes
        isRunning = true
        isPaused = false
        scheduleTimer()
    }

    func pause() {
        isPaused = true
        isRunning = false
        timer?.invalidate()
    }

    func resume() {
        isPaused = false
        isRunning = true
        scheduleTimer()
    }

    func finish() {
        let elapsed = (totalTime - timeRemaining) / 60
        let session = FocusSession(
            blockName: currentBlockName,
            category: currentCategory,
            targetMinutes: totalTime / 60,
            actualMinutes: elapsed,
            isCompleted: timeRemaining == 0
        )
        sessions.append(session)
        reset()
        showCompletionCelebration = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.showCompletionCelebration = false
        }
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        timeRemaining = selectedMinutes * 60
        totalTime = selectedMinutes * 60
    }

    func setDuration(_ minutes: Int) {
        selectedMinutes = minutes
        if !isRunning && !isPaused {
            timeRemaining = minutes * 60
            totalTime = minutes * 60
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.finish()
            }
        }
    }

    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) {
            sessions = decoded
        }
    }

    deinit {
        timer?.invalidate()
    }
}
