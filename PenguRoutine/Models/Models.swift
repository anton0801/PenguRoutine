import SwiftUI
import Foundation

enum RoutineOutcome {
    case huddled
    case requestConsent
    case openFloes
    case driftedToColony
}

struct GlacierConstants {
    static let appCode = "6771748870"
    static let trackerKey = "BPFHkq9LnVDGn3CQnvvzji"
    static let suiteGlacier = "group.pengu.routine.glacier"
    static let cookieFloes = "pengu_routine_floes"
    static let backendIceberg = "https://penguroutine.com/config.php"
    static let logFlipper = "🐧 [PenguRoutine]"
    static let cipherFile = "pr_glacier_cipher.bin"
}

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

struct GlacierKey {
    static let floesURL = "pr_floes_url"
    static let floesMode = "pr_floes_mode"
    static let primed = "pr_primed"
    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
}

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

enum RoutineFault: Error, Comparable {
    
    case quietBurrow
    case echoMissed
    
    case wireFrozen(attempts: Int)
    case currentClogged(retryAfter: TimeInterval)
    case beaconExpired
    case packetCracked(stage: String)
    
    case voltageDimmed
    case floesDenied(httpCode: Int)
    
    private var priority: Int {
        switch self {
        case .quietBurrow: return 1
        case .echoMissed: return 2
        case .wireFrozen: return 10
        case .currentClogged: return 11
        case .beaconExpired: return 12
        case .packetCracked: return 13
        case .voltageDimmed: return 50
        case .floesDenied: return 51
        }
    }
    
    static func < (lhs: RoutineFault, rhs: RoutineFault) -> Bool {
        lhs.priority < rhs.priority
    }
    
    var tag: String {
        switch self {
        case .quietBurrow: return "quietBurrow"
        case .echoMissed: return "echoMissed"
        case .wireFrozen: return "wireFrozen"
        case .currentClogged: return "currentClogged"
        case .beaconExpired: return "beaconExpired"
        case .packetCracked: return "packetCracked"
        case .voltageDimmed: return "voltageDimmed"
        case .floesDenied: return "floesDenied"
        }
    }
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

struct GlacierRecord: Codable {
    let chirps: [String: String]
    let waddles: [String: String]
    let floesURL: String?
    let floesMode: String?
    let untrodden: Bool
    let consentChilled: Bool
    let consentThawed: Bool
    let consentMarkedAt: Date?
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
