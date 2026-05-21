import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                RoutineView()
                    .tag(1)
                FocusTimerView()
                    .tag(2)
                CalendarStatsView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            .tabViewStyle(DefaultTabViewStyle())

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .onAppear {
            appState.checkAndUpdateStreak()
            // Hide default tab bar
            UITabBar.appearance().isHidden = true
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let items: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("square.stack.3d.up.fill", "Routine"),
        ("timer", "Focus"),
        ("chart.bar.fill", "Stats"),
        ("gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { i in
                Button {
                    withAnimation(PenguTheme.spring()) {
                        selectedTab = i
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == i {
                                Circle()
                                    .fill(PenguTheme.iceGradient)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: PenguTheme.iceShadow(0.45), radius: 10, x: 0, y: 4)
                            }
                            Image(systemName: items[i].icon)
                                .font(.system(size: selectedTab == i ? 20 : 18, weight: .semibold))
                                .foregroundColor(selectedTab == i ? .white : PenguTheme.activeBlue.opacity(0.5))
                        }
                        .frame(width: 44, height: 44)

                        Text(items[i].label)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(selectedTab == i ? PenguTheme.activeBlue : PenguTheme.darkText.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.97), Color(hex: "E0F2FE").opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: PenguTheme.iceShadow(0.25), radius: 20, x: 0, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
