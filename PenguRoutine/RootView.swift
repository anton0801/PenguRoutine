import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(onFinish: {
                    appState.hasCompletedOnboarding = true
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showOnboarding = false
                    }
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showOnboarding)
        .preferredColorScheme(appState.colorScheme)
    }
}
