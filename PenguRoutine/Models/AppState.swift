import SwiftUI
import Combine

class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("themeMode") var themeMode: String = "system" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false {
        didSet { handleNotificationChange() }
    }
    @AppStorage("dailyReminderTime") var dailyReminderTime: Double = 8.0 * 3600 {
        didSet { rescheduleReminders() }
    }
    @AppStorage("animationSpeed") var animationSpeed: String = "normal"
    @AppStorage("accentColorName") var accentColorName: String = "ice"
    @AppStorage("language") var language: String = "English"
    @AppStorage("backupEnabled") var backupEnabled: Bool = false
    @AppStorage("snowStreak") var snowStreak: Int = 0
    @AppStorage("lastActiveDate") var lastActiveDate: String = ""

    var colorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var animDuration: Double {
        switch animationSpeed {
        case "fast": return 0.25
        case "slow": return 0.7
        default: return 0.4
        }
    }

    func handleNotificationChange() {
        if notificationsEnabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        self.rescheduleReminders()
                    } else {
                        self.notificationsEnabled = false
                    }
                }
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    func rescheduleReminders() {
        guard notificationsEnabled else { return }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let content = UNMutableNotificationContent()
        content.title = "🐧 Pengu Routine"
        content.body = "Time to plan your icy day! Build your blocks."
        content.sound = .default
        let hour = Int(dailyReminderTime / 3600)
        let minute = Int((dailyReminderTime.truncatingRemainder(dividingBy: 3600)) / 60)
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func checkAndUpdateStreak() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        if lastActiveDate == today { return }
        let yesterday = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        if lastActiveDate == yesterday {
            snowStreak += 1
        } else if lastActiveDate != today {
            snowStreak = 1
        }
        lastActiveDate = today
    }
}

import UserNotifications
