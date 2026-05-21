import SwiftUI

@main
struct PenguRoutineApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var routineVM = RoutineViewModel()
    @StateObject private var timerVM = FocusTimerViewModel()
    @StateObject private var statsVM = StatsViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(routineVM)
                .environmentObject(timerVM)
                .environmentObject(statsVM)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}
