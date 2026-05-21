import SwiftUI
import Combine

class RoutineViewModel: ObservableObject {
    @Published var blocks: [IceBlock] = [] {
        didSet { save() }
    }
    @Published var selectedDate: Date = Date()
    @Published var showAddBlock: Bool = false
    @Published var editingBlock: IceBlock? = nil

    private let storageKey = "ice_blocks"

    init() {
        load()
        if blocks.isEmpty { loadDefaults() }
    }

    var todayBlocks: [IceBlock] {
        blocks.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.startTime < $1.startTime }
    }

    var completedToday: Int {
        todayBlocks.filter { $0.isCompleted }.count
    }

    var completionRate: Double {
        guard !todayBlocks.isEmpty else { return 0 }
        return Double(completedToday) / Double(todayBlocks.count)
    }

    func addBlock(_ block: IceBlock) {
        blocks.append(block)
    }

    func updateBlock(_ block: IceBlock) {
        if let idx = blocks.firstIndex(where: { $0.id == block.id }) {
            blocks[idx] = block
        }
    }

    func deleteBlock(_ block: IceBlock) {
        blocks.removeAll { $0.id == block.id }
    }

    func toggleCompletion(_ block: IceBlock) {
        if let idx = blocks.firstIndex(where: { $0.id == block.id }) {
            blocks[idx].isCompleted.toggle()
        }
    }

    func duplicateBlock(_ block: IceBlock) {
        var copy = block
        copy.id = UUID()
        copy.isCompleted = false
        blocks.append(copy)
    }

    func blocksForDate(_ date: Date) -> [IceBlock] {
        blocks.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func completionForDate(_ date: Date) -> Double {
        let dayBlocks = blocksForDate(date)
        guard !dayBlocks.isEmpty else { return 0 }
        return Double(dayBlocks.filter { $0.isCompleted }.count) / Double(dayBlocks.count)
    }

    func datesWithBlocks(in month: Date) -> Set<String> {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: month)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var result = Set<String>()
        for block in blocks {
            let bc = cal.dateComponents([.year, .month], from: block.date)
            if bc.year == comps.year && bc.month == comps.month {
                result.insert(formatter.string(from: block.date))
            }
        }
        return result
    }

    private func save() {
        if let data = try? JSONEncoder().encode(blocks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([IceBlock].self, from: data) {
            blocks = decoded
        }
    }

    private func loadDefaults() {
        let now = Date()
        let cal = Calendar.current
        func time(_ h: Int, _ m: Int) -> Date {
            cal.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now
        }
        blocks = [
            IceBlock(name: "Morning Sport", category: .sport, startTime: time(7, 0), durationMinutes: 30, notes: "Stretch + run", date: now),
            IceBlock(name: "Deep Work", category: .work, startTime: time(9, 0), durationMinutes: 90, notes: "Focus session", date: now),
            IceBlock(name: "Hydration Break", category: .water, startTime: time(11, 0), durationMinutes: 10, notes: "Drink 500ml", date: now),
            IceBlock(name: "Lunch & Rest", category: .rest, startTime: time(13, 0), durationMinutes: 60, notes: "Relax", date: now),
            IceBlock(name: "Study Session", category: .study, startTime: time(15, 0), durationMinutes: 60, notes: "Read / learn", date: now),
            IceBlock(name: "Evening Walk", category: .sport, startTime: time(18, 0), durationMinutes: 30, notes: "Fresh air", date: now),
            IceBlock(name: "Wind Down", category: .sleep, startTime: time(22, 0), durationMinutes: 30, notes: "Prepare for sleep", date: now),
        ]
    }
}
