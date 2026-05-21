import SwiftUI
import Combine

class StatsViewModel: ObservableObject {
    @Published var selectedPeriod: StatPeriod = .week
    @Published var weeklyData: [DayStats] = []

    enum StatPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    struct DayStats: Identifiable {
        var id = UUID()
        var date: Date
        var completedBlocks: Int
        var totalBlocks: Int
        var focusMinutes: Int
        var label: String {
            let f = DateFormatter()
            f.dateFormat = "EEE"
            return f.string(from: date)
        }
        var completionRate: Double {
            guard totalBlocks > 0 else { return 0 }
            return Double(completedBlocks) / Double(totalBlocks)
        }
    }

    func refresh(blocks: [IceBlock], sessions: [FocusSession]) {
        let cal = Calendar.current
        let today = Date()
        weeklyData = (0..<7).reversed().map { offset -> DayStats in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let dayBlocks = blocks.filter { cal.isDate($0.date, inSameDayAs: date) }
            let completed = dayBlocks.filter { $0.isCompleted }.count
            let focusMins = sessions
                .filter { cal.isDate($0.date, inSameDayAs: date) && $0.isCompleted }
                .reduce(0) { $0 + $1.actualMinutes }
            return DayStats(date: date, completedBlocks: completed, totalBlocks: dayBlocks.count, focusMinutes: focusMins)
        }
    }

    func categoryBreakdown(blocks: [IceBlock]) -> [(BlockCategory, Int)] {
        var counts: [BlockCategory: Int] = [:]
        let today = Date()
        let cal = Calendar.current
        let relevant = blocks.filter {
            if selectedPeriod == .week {
                return cal.dateComponents([.weekOfYear, .year], from: $0.date) == cal.dateComponents([.weekOfYear, .year], from: today)
            }
            return true
        }
        for block in relevant {
            counts[block.category, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }

    func totalFocusHours(sessions: [FocusSession]) -> Double {
        Double(sessions.filter { $0.isCompleted }.reduce(0) { $0 + $1.actualMinutes }) / 60.0
    }

    func bestStreak(blocks: [IceBlock]) -> Int {
        var streak = 0
        var best = 0
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for i in 0..<365 {
            let day = cal.date(byAdding: .day, value: -i, to: today)!
            let dayBlocks = blocks.filter { cal.isDate($0.date, inSameDayAs: day) }
            if !dayBlocks.isEmpty && dayBlocks.allSatisfy({ $0.isCompleted }) {
                streak += 1
                best = max(best, streak)
            } else {
                streak = 0
            }
        }
        return best
    }
}
