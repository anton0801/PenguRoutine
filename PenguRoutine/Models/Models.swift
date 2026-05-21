import SwiftUI
import Foundation

// MARK: - Block Category
enum BlockCategory: String, Codable, CaseIterable {
    case work = "Work"
    case rest = "Rest"
    case water = "Water"
    case sport = "Sport"
    case sleep = "Sleep"
    case study = "Study"
    case meal = "Meal"
    case social = "Social"

    var icon: String {
        switch self {
        case .work: return "laptopcomputer"
        case .rest: return "moon.stars.fill"
        case .water: return "drop.fill"
        case .sport: return "figure.run"
        case .sleep: return "bed.double.fill"
        case .study: return "book.fill"
        case .meal: return "fork.knife"
        case .social: return "person.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .work: return Color(hex: "38BDF8")
        case .rest: return Color(hex: "A78BFA")
        case .water: return Color(hex: "22D3EE")
        case .sport: return Color(hex: "22C55E")
        case .sleep: return Color(hex: "818CF8")
        case .study: return Color(hex: "FBBF24")
        case .meal: return Color(hex: "FB923C")
        case .social: return Color(hex: "F472B6")
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Ice Block
struct IceBlock: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var category: BlockCategory
    var startTime: Date
    var durationMinutes: Int
    var notes: String = ""
    var isCompleted: Bool = false
    var date: Date

    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startTime) ?? startTime
    }

    var timeRangeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: startTime)) – \(f.string(from: endTime))"
    }
}

// MARK: - Routine Day
struct RoutineDay: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var blocks: [IceBlock]
    var completionRate: Double {
        guard !blocks.isEmpty else { return 0 }
        return Double(blocks.filter { $0.isCompleted }.count) / Double(blocks.count)
    }
}

// MARK: - Focus Session
struct FocusSession: Identifiable, Codable {
    var id: UUID = UUID()
    var blockId: UUID?
    var blockName: String
    var category: BlockCategory
    var targetMinutes: Int
    var actualMinutes: Int = 0
    var date: Date = Date()
    var isCompleted: Bool = false
}

// MARK: - Reward
struct Reward: Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var icon: String
    var requiredStreak: Int
    var isUnlocked: Bool = false
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
