import SwiftUI

@main
struct PenguRoutineApp: App {
    
    @StateObject private var appState = AppState()
    @StateObject private var routineVM = RoutineViewModel()
    @StateObject private var timerVM = FocusTimerViewModel()
    @StateObject private var statsVM = StatsViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegator

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
                .environmentObject(routineVM)
                .environmentObject(timerVM)
                .environmentObject(statsVM)
        }
    }
}
