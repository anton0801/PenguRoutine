import SwiftUI

final class NotificationConsentChirper: ConsentChirper {
    
    func chirp() async -> Bool {
        await UNUserNotificationCenter.current()
            .requestAuthorizationAsync(options: [.alert, .sound, .badge])
    }
    
    func armPushSignal() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
