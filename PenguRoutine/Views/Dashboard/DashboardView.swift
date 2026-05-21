import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var routineVM: RoutineViewModel
    @EnvironmentObject var timerVM: FocusTimerViewModel
    @EnvironmentObject var appState: AppState
    @State private var showAddBlock = false
    @State private var animIn = false

    var body: some View {
        NavigationView {
            ZStack {
                PenguTheme.skyGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 8)

                        // Header
                        dashboardHeader

                        // Status card
                        statusCard

                        // Quick stats row
                        quickStatsRow

                        // Today's blocks preview
                        todayBlocksPreview

                        // Quick actions
                        quickActions

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, PenguTheme.horizontalPadding)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { animIn = true }
        }
        .sheet(isPresented: $showAddBlock) {
            AddBlockView(isPresented: $showAddBlock)
                .environmentObject(routineVM)
        }
    }

    private var dashboardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(PenguTheme.captionFont(14))
                    .foregroundColor(PenguTheme.activeBlue)
                Text("Your Ice Day")
                    .font(PenguTheme.titleFont(26))
                    .foregroundColor(PenguTheme.darkText)
            }
            Spacer()
            // Snow streak badge
            HStack(spacing: 6) {
                Image(systemName: "snowflake")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "38BDF8"))
                Text("\(appState.snowStreak)")
                    .font(PenguTheme.titleFont(16))
                    .foregroundColor(PenguTheme.darkText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: PenguTheme.iceShadow(0.2), radius: 8, x: 0, y: 2)
            )
        }
        .opacity(animIn ? 1 : 0)
        .offset(y: animIn ? 0 : -20)
    }

    private var statusCard: some View {
        HStack(spacing: 16) {
            PenguinView(size: 70, isAnimating: true)

            VStack(alignment: .leading, spacing: 8) {
                Text(statusMessage)
                    .font(PenguTheme.titleFont(17))
                    .foregroundColor(.white)
                    .lineLimit(2)

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: geo.size.width * routineVM.completionRate, height: 8)
                                .animation(PenguTheme.spring(), value: routineVM.completionRate)
                        }
                    }
                    .frame(height: 8)

                    Text("\(routineVM.completedToday)/\(routineVM.todayBlocks.count) blocks done")
                        .font(PenguTheme.captionFont(12))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: PenguTheme.cornerRadius)
                .fill(PenguTheme.deepIceGradient)
                .shadow(color: PenguTheme.iceShadow(0.4), radius: 16, x: 0, y: 6)
        )
        .opacity(animIn ? 1 : 0)
        .offset(y: animIn ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: animIn)
    }

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            StatMiniCard(icon: "flame.fill", label: "Focus", value: "\(timerVM.totalFocusMinutesToday)m", color: Color(hex: "F97316"))
            StatMiniCard(icon: "checkmark.circle.fill", label: "Sessions", value: "\(timerVM.completedSessionsToday)", color: PenguTheme.stateNormal)
            StatMiniCard(icon: "snowflake", label: "Streak", value: "\(appState.snowStreak)d", color: PenguTheme.iceBlue)
        }
        .opacity(animIn ? 1 : 0)
        .offset(y: animIn ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: animIn)
    }

    private var todayBlocksPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Blocks")
                    .font(PenguTheme.titleFont(18))
                    .foregroundColor(PenguTheme.darkText)
                Spacer()
                Button("See All") {}
                    .font(PenguTheme.bodyFont(14))
                    .foregroundColor(PenguTheme.activeBlue)
            }

            if routineVM.todayBlocks.isEmpty {
                EmptyBlocksPlaceholder(onAdd: { showAddBlock = true })
            } else {
                ForEach(routineVM.todayBlocks.prefix(4)) { block in
                    DashboardBlockRow(block: block)
                        .environmentObject(routineVM)
                }
                if routineVM.todayBlocks.count > 4 {
                    Text("+ \(routineVM.todayBlocks.count - 4) more blocks")
                        .font(PenguTheme.captionFont(13))
                        .foregroundColor(PenguTheme.activeBlue)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .opacity(animIn ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: animIn)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(PenguTheme.titleFont(18))
                .foregroundColor(PenguTheme.darkText)

            HStack(spacing: 12) {
                QuickActionButton(icon: "plus.circle.fill", label: "Add Block", color: PenguTheme.iceBlue) {
                    showAddBlock = true
                }
                QuickActionButton(icon: "timer", label: "Start Focus", color: PenguTheme.stateNormal) {}
                QuickActionButton(icon: "chart.bar.fill", label: "View Stats", color: Color(hex: "818CF8")) {}
            }
        }
        .opacity(animIn ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: animIn)
    }

    private var greetingText: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning ☀️" }
        if h < 17 { return "Good afternoon 🌤" }
        return "Good evening 🌙"
    }

    private var statusMessage: String {
        let rate = routineVM.completionRate
        if rate == 0 { return "Ready to build\nyour ice day!" }
        if rate < 0.5 { return "Great start!\nKeep going!" }
        if rate < 1.0 { return "Amazing progress!\nAlmost done!" }
        return "Perfect day! 🎉\nAll blocks done!"
    }
}

struct StatMiniCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(PenguTheme.titleFont(18))
                .foregroundColor(PenguTheme.darkText)
            Text(label)
                .font(PenguTheme.captionFont(11))
                .foregroundColor(PenguTheme.darkText.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .iceCard()
    }
}

struct DashboardBlockRow: View {
    let block: IceBlock
    @EnvironmentObject var routineVM: RoutineViewModel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(block.category.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: block.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(block.category.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(block.name)
                    .font(PenguTheme.bodyFont(15))
                    .foregroundColor(PenguTheme.darkText)
                    .strikethrough(block.isCompleted, color: PenguTheme.darkText.opacity(0.4))
                Text(block.timeRangeString)
                    .font(PenguTheme.captionFont(12))
                    .foregroundColor(PenguTheme.darkText.opacity(0.5))
            }
            Spacer()
            Button {
                withAnimation(PenguTheme.spring()) {
                    routineVM.toggleCompletion(block)
                }
            } label: {
                Image(systemName: block.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(block.isCompleted ? PenguTheme.stateNormal : PenguTheme.iceBlue.opacity(0.4))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.85))
                .shadow(color: PenguTheme.iceShadow(0.12), radius: 6, x: 0, y: 2)
        )
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(PenguTheme.spring()) { pressed = false }
            }
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                Text(label)
                    .font(PenguTheme.captionFont(12))
                    .foregroundColor(PenguTheme.darkText.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: PenguTheme.iceShadow(0.15), radius: 8, x: 0, y: 3)
            )
            .scaleEffect(pressed ? 0.94 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyBlocksPlaceholder: View {
    var onAdd: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 36))
                .foregroundColor(PenguTheme.iceBlue.opacity(0.4))
            Text("No blocks yet today")
                .font(PenguTheme.bodyFont(15))
                .foregroundColor(PenguTheme.darkText.opacity(0.5))
            Button("Add First Block", action: onAdd)
                .font(PenguTheme.bodyFont(15))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(PenguTheme.iceGradient))
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .iceCard()
    }
}
