import SwiftUI

struct FocusTimerView: View {
    @EnvironmentObject var timerVM: FocusTimerViewModel
    @EnvironmentObject var routineVM: RoutineViewModel
    @EnvironmentObject var appState: AppState
    @State private var showBlockPicker = false
    @State private var showCelebration = false

    var body: some View {
        NavigationView {
            ZStack {
                // Deep ice background
                LinearGradient(
                    colors: [Color(hex: "0F172A"), Color(hex: "0C4A6E"), Color(hex: "075985")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Ice particle bg
                IceParticleBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        Spacer().frame(height: 8)

                        // Header
                        VStack(spacing: 4) {
                            Text("Ice Focus")
                                .font(PenguTheme.titleFont(28))
                                .foregroundColor(.white)
                            Text(timerVM.isRunning || timerVM.isPaused ? timerVM.currentBlockName : "Select a block to start")
                                .font(PenguTheme.bodyFont(15))
                                .foregroundColor(Color(hex: "7DD3FC"))
                        }

                        // Circular Timer
                        IceTimerCircle(
                            progress: timerVM.progress,
                            timeString: timerVM.timeString,
                            category: timerVM.currentCategory,
                            isRunning: timerVM.isRunning
                        )

                        // Duration selector (when not running)
                        if !timerVM.isRunning && !timerVM.isPaused {
                            DurationPicker(selectedMinutes: $timerVM.selectedMinutes) { mins in
                                timerVM.setDuration(mins)
                            }
                        }

                        // Control buttons
                        timerControls

                        // Sessions today
                        if timerVM.completedSessionsToday > 0 || timerVM.totalFocusMinutesToday > 0 {
                            todayStats
                        }

                        // Recent sessions
                        if !timerVM.sessions.isEmpty {
                            recentSessions
                        }

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 20)
                }

                // Completion celebration overlay
                if timerVM.showCompletionCelebration {
                    CelebrationOverlay()
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showBlockPicker) {
            BlockPickerSheet(isPresented: $showBlockPicker) { block in
                timerVM.start(blockName: block.name, category: block.category, minutes: block.durationMinutes)
            }
            .environmentObject(routineVM)
        }
        .onChange(of: timerVM.showCompletionCelebration) { showing in
            if showing { appState.checkAndUpdateStreak() }
        }
    }

    private var timerControls: some View {
        VStack(spacing: 16) {
            if !timerVM.isRunning && !timerVM.isPaused {
                // Start buttons
                VStack(spacing: 12) {
                    Button {
                        timerVM.start(blockName: "Focus Session", category: .work, minutes: timerVM.selectedMinutes)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                            Text("Start Focus")
                        }
                        .font(PenguTheme.titleFont(18))
                        .foregroundColor(Color(hex: "0F172A"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(PenguTheme.iceGradient)
                                .shadow(color: Color(hex: "38BDF8").opacity(0.5), radius: 16, x: 0, y: 6)
                        )
                    }

                    Button {
                        showBlockPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.stack.3d.up")
                            Text("Pick Ice Block")
                        }
                        .font(PenguTheme.bodyFont(16))
                        .foregroundColor(Color(hex: "7DD3FC"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color(hex: "38BDF8").opacity(0.4), lineWidth: 1.5)
                        )
                    }
                }
            } else if timerVM.isRunning {
                // Running controls
                HStack(spacing: 16) {
                    Button {
                        withAnimation(PenguTheme.spring()) { timerVM.pause() }
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "7DD3FC"))
                            .frame(width: 64, height: 64)
                            .background(Circle().stroke(Color(hex: "38BDF8").opacity(0.4), lineWidth: 1.5))
                    }

                    Button {
                        timerVM.finish()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Finish")
                        }
                        .font(PenguTheme.titleFont(18))
                        .foregroundColor(Color(hex: "0F172A"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(RoundedRectangle(cornerRadius: 30).fill(PenguTheme.iceGradient))
                    }
                }
            } else if timerVM.isPaused {
                // Paused controls
                HStack(spacing: 16) {
                    Button {
                        withAnimation(PenguTheme.spring()) { timerVM.reset() }
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 18))
                            .foregroundColor(PenguTheme.stateMiss)
                            .frame(width: 64, height: 64)
                            .background(Circle().stroke(PenguTheme.stateMiss.opacity(0.3), lineWidth: 1.5))
                    }

                    Button {
                        withAnimation(PenguTheme.spring()) { timerVM.resume() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .font(PenguTheme.titleFont(18))
                        .foregroundColor(Color(hex: "0F172A"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(RoundedRectangle(cornerRadius: 30).fill(PenguTheme.iceGradient))
                    }
                }
            }
        }
    }

    private var todayStats: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(timerVM.totalFocusMinutesToday)")
                    .font(PenguTheme.titleFont(24))
                    .foregroundColor(.white)
                Text("minutes focused")
                    .font(PenguTheme.captionFont(12))
                    .foregroundColor(Color(hex: "7DD3FC"))
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 40)

            VStack(spacing: 4) {
                Text("\(timerVM.completedSessionsToday)")
                    .font(PenguTheme.titleFont(24))
                    .foregroundColor(.white)
                Text("sessions done")
                    .font(PenguTheme.captionFont(12))
                    .foregroundColor(Color(hex: "7DD3FC"))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "38BDF8").opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(PenguTheme.titleFont(16))
                .foregroundColor(.white)

            ForEach(timerVM.sessions.suffix(3).reversed()) { session in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(session.category.color.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: session.category.icon)
                            .font(.system(size: 14))
                            .foregroundColor(session.category.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.blockName)
                            .font(PenguTheme.bodyFont(14))
                            .foregroundColor(.white)
                        Text("\(session.actualMinutes)m / \(session.targetMinutes)m")
                            .font(PenguTheme.captionFont(12))
                            .foregroundColor(Color(hex: "7DD3FC"))
                    }
                    Spacer()
                    Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(session.isCompleted ? PenguTheme.stateNormal : PenguTheme.stateMiss)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.07))
                )
            }
        }
    }
}

// MARK: - Ice Timer Circle
struct IceTimerCircle: View {
    let progress: Double
    let timeString: String
    let category: BlockCategory
    let isRunning: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Glow rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color(hex: "38BDF8").opacity(glowOpacity - Double(i) * 0.08), lineWidth: 1)
                    .frame(width: 220 + CGFloat(i) * 22, height: 220 + CGFloat(i) * 22)
                    .scaleEffect(pulseScale)
            }

            // Background circle
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 220, height: 220)

            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 12)
                .frame(width: 200, height: 200)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color(hex: "22D3EE"), Color(hex: "38BDF8"), Color(hex: "0EA5E9")]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(PenguTheme.spring(), value: progress)

            // Center content
            VStack(spacing: 8) {
                PenguinView(size: 44, isAnimating: isRunning)

                Text(timeString)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: category.icon)
                        .font(.system(size: 11))
                    Text(category.rawValue)
                        .font(PenguTheme.captionFont(12))
                }
                .foregroundColor(Color(hex: "7DD3FC"))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.04
                glowOpacity = 0.55
            }
        }
    }
}

// MARK: - Duration Picker
struct DurationPicker: View {
    @Binding var selectedMinutes: Int
    var onChange: (Int) -> Void

    let options = [5, 10, 15, 20, 25, 30, 45, 60, 90]

    var body: some View {
        VStack(spacing: 10) {
            Text("Duration")
                .font(PenguTheme.captionFont(13))
                .foregroundColor(Color(hex: "7DD3FC"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(options, id: \.self) { mins in
                        Button {
                            withAnimation(PenguTheme.spring()) {
                                selectedMinutes = mins
                                onChange(mins)
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(mins)")
                                    .font(PenguTheme.titleFont(16))
                                Text("min")
                                    .font(PenguTheme.captionFont(10))
                            }
                            .foregroundColor(selectedMinutes == mins ? Color(hex: "0F172A") : Color(hex: "7DD3FC"))
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(selectedMinutes == mins ? AnyShapeStyle(PenguTheme.iceGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Block Picker Sheet
struct BlockPickerSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var routineVM: RoutineViewModel
    var onSelect: (IceBlock) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                PenguTheme.skyGradient.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(routineVM.todayBlocks.filter { !$0.isCompleted }) { block in
                            Button {
                                onSelect(block)
                                isPresented = false
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(block.category.gradient)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: block.category.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(block.name)
                                            .font(PenguTheme.bodyFont(15))
                                            .foregroundColor(PenguTheme.darkText)
                                        Text("\(block.durationMinutes)min • \(block.timeRangeString)")
                                            .font(PenguTheme.captionFont(12))
                                            .foregroundColor(PenguTheme.darkText.opacity(0.5))
                                    }
                                    Spacer()
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(PenguTheme.iceBlue)
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.85)))
                            }
                        }

                        if routineVM.todayBlocks.filter({ !$0.isCompleted }).isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(PenguTheme.stateNormal)
                                Text("All blocks completed!")
                                    .font(PenguTheme.bodyFont(16))
                                    .foregroundColor(PenguTheme.darkText.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Pick a Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(PenguTheme.activeBlue)
                }
            }
        }
    }
}

// MARK: - Celebration Overlay
struct CelebrationOverlay: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var particles: [CelebrationParticle] = []

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            ForEach(particles) { p in
                Text(p.emoji)
                    .font(.system(size: p.size))
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }

            VStack(spacing: 16) {
                PenguinView(size: 80, isAnimating: true)
                Text("Great job! 🎉")
                    .font(PenguTheme.titleFont(28))
                    .foregroundColor(.white)
                Text("Session complete!")
                    .font(PenguTheme.bodyFont(16))
                    .foregroundColor(Color(hex: "7DD3FC"))
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0C4A6E"), Color(hex: "075985")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: "38BDF8").opacity(0.4), radius: 24, x: 0, y: 8)
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                scale = 1.0
                opacity = 1.0
            }
            let w = UIScreen.main.bounds.width
            let h = UIScreen.main.bounds.height
            particles = (0..<20).map { _ in
                CelebrationParticle(
                    emoji: ["❄️", "🌨️", "⭐️", "✨", "🎉"].randomElement()!,
                    x: CGFloat.random(in: 0...w),
                    y: CGFloat.random(in: 0...h),
                    size: CGFloat.random(in: 14...28),
                    opacity: Double.random(in: 0.6...1.0)
                )
            }
            withAnimation(.easeOut(duration: 1.5).delay(0.8)) {
                for i in 0..<particles.count {
                    particles[i].opacity = 0
                }
            }
        }
    }
}

struct CelebrationParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    var opacity: Double
}

// MARK: - Ice Particle Background
struct IceParticleBackground: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Circle()
                    .fill(Color(hex: "38BDF8").opacity(0.04))
                    .frame(width: CGFloat([80, 120, 60, 100, 90, 70, 110, 55][i]))
                    .position(
                        x: CGFloat([40, 320, 180, 60, 340, 200, 100, 280][i]),
                        y: CGFloat([120, 80, 200, 400, 350, 600, 700, 500][i])
                    )
                    .offset(y: phase * CGFloat([0.5, -0.4, 0.6, -0.3, 0.7, -0.5, 0.4, -0.6][i]))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                phase = 20
            }
        }
        .allowsHitTesting(false)
    }
}
