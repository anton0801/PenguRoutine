import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var currentPage = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            PenguTheme.skyGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        hasCompletedOnboarding = true
                        onFinish()
                    }
                    .font(PenguTheme.bodyFont(15))
                    .foregroundColor(PenguTheme.activeBlue)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Page content
                TabView(selection: $currentPage) {
                    OnboardingPage1()
                        .tag(0)
                    OnboardingPage2()
                        .tag(1)
                    OnboardingPage3()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? PenguTheme.activeBlue : PenguTheme.iceBlue.opacity(0.3))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(PenguTheme.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Next / Get Started button
                Button {
                    if currentPage < 2 {
                        withAnimation(PenguTheme.spring()) { currentPage += 1 }
                    } else {
                        hasCompletedOnboarding = true
                        onFinish()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage == 2 ? "Get Started" : "Next")
                            .font(PenguTheme.titleFont(17))
                        Image(systemName: currentPage == 2 ? "snowflake" : "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(PenguTheme.iceGradient)
                    .cornerRadius(28)
                    .shadow(color: PenguTheme.iceShadow(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Page 1: Tap interaction
struct OnboardingPage1: View {
    @State private var particles: [ParticleEffect] = []
    @State private var iconScale: CGFloat = 1.0
    @State private var tapped = false
    @State private var snowfall = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                // Burst particles
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .offset(x: p.offsetX, y: p.offsetY)
                        .opacity(p.opacity)
                }

                Button {
                    triggerBurst()
                } label: {
                    ZStack {
                        Circle()
                            .fill(PenguTheme.iceGradient)
                            .frame(width: 140, height: 140)
                            .shadow(color: PenguTheme.iceShadow(0.4), radius: 20, x: 0, y: 8)

                        VStack(spacing: 8) {
                            PenguinView(size: 60, isAnimating: true)
                            if tapped {
                                Text("🎉")
                                    .font(.system(size: 20))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .scaleEffect(iconScale)
                }
            }
            .frame(height: 200)

            Text("Tap the penguin!")
                .font(PenguTheme.captionFont(14))
                .foregroundColor(PenguTheme.activeBlue)
                .opacity(tapped ? 0 : 1)

            VStack(spacing: 12) {
                Text("Organize your activity")
                    .font(PenguTheme.titleFont(28))
                    .foregroundColor(PenguTheme.darkText)
                    .multilineTextAlignment(.center)

                Text("Keep important actions in one place.\nBuild your day with beautiful ice blocks.")
                    .font(PenguTheme.bodyFont(16))
                    .foregroundColor(PenguTheme.darkText.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func triggerBurst() {
        tapped = true
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            iconScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                iconScale = 1.0
            }
        }
        particles = (0..<12).map { i in
            let angle = Double(i) / 12.0 * .pi * 2
            let dist = CGFloat.random(in: 50...100)
            return ParticleEffect(
                color: [PenguTheme.iceBlue, PenguTheme.iceGlow, PenguTheme.stateHappy, Color.white].randomElement()!,
                size: CGFloat.random(in: 6...14),
                offsetX: CGFloat(cos(angle)) * dist,
                offsetY: CGFloat(sin(angle)) * dist,
                opacity: 1.0
            )
        }
        withAnimation(.easeOut(duration: 0.8)) {
            for i in 0..<particles.count {
                particles[i].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            particles = []
        }
    }
}

// MARK: - Page 2: Drag interaction
struct OnboardingPage2: View {
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var fillLevel: CGFloat = 0.3
    @State private var hint = true

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                // Ice glass visual
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "E0F2FE"))
                    .frame(width: 100, height: 160)
                    .overlay(
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(PenguTheme.iceGradient)
                                .frame(height: 160 * fillLevel)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: PenguTheme.iceShadow(0.3), radius: 15, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "38BDF8").opacity(0.3), lineWidth: 1.5)
                    )

                // Progress label
                Text("\(Int(fillLevel * 100))%")
                    .font(PenguTheme.titleFont(18))
                    .foregroundColor(.white)
                    .opacity(fillLevel > 0.25 ? 1 : 0)
            }
            .gesture(
                DragGesture()
                    .onChanged { v in
                        isDragging = true
                        hint = false
                        let delta = -v.translation.height / 160
                        fillLevel = max(0.05, min(1.0, fillLevel + delta * 0.005))
                    }
                    .onEnded { _ in isDragging = false }
            )
            .offset(y: dragOffset.height * 0.05)
            .animation(PenguTheme.spring(), value: fillLevel)

            if hint {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.and.down")
                        .font(.system(size: 12))
                    Text("Drag to fill your day")
                        .font(PenguTheme.captionFont(14))
                }
                .foregroundColor(PenguTheme.activeBlue)
                .transition(.opacity)
            }

            VStack(spacing: 12) {
                Text("Track your progress")
                    .font(PenguTheme.titleFont(28))
                    .foregroundColor(PenguTheme.darkText)
                    .multilineTextAlignment(.center)

                Text("Use stats, history and reminders.\nWatch your snow streak grow day by day.")
                    .font(PenguTheme.bodyFont(16))
                    .foregroundColor(PenguTheme.darkText.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

// MARK: - Page 3: Scroll-driven parallax
struct OnboardingPage3: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var iconsScale: CGFloat = 0.8
    @State private var iconsOpacity: Double = 0

    let features: [(String, String, Color)] = [
        ("timer.circle.fill", "Ice Focus Timer", Color(hex: "38BDF8")),
        ("snowflake", "Snow Streak", Color(hex: "22D3EE")),
        ("chart.bar.fill", "Smart Stats", Color(hex: "22C55E")),
        ("calendar", "Calendar View", Color(hex: "818CF8")),
        ("star.fill", "Ice Rewards", Color(hex: "FACC15"))
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated feature cards
            VStack(spacing: 12) {
                ForEach(Array(features.enumerated()), id: \.offset) { idx, feature in
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(feature.2.opacity(0.15))
                                .frame(width: 46, height: 46)
                            Image(systemName: feature.0)
                                .font(.system(size: 20))
                                .foregroundColor(feature.2)
                        }
                        Text(feature.1)
                            .font(PenguTheme.bodyFont(16))
                            .foregroundColor(PenguTheme.darkText)
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(PenguTheme.stateNormal)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.8))
                            .shadow(color: PenguTheme.iceShadow(0.15), radius: 8, x: 0, y: 3)
                    )
                    .scaleEffect(iconsScale)
                    .opacity(iconsOpacity)
                    .animation(
                        PenguTheme.spring().delay(Double(idx) * 0.08),
                        value: iconsScale
                    )
                }
            }
            .padding(.horizontal, 32)
            .onAppear {
                withAnimation(PenguTheme.slowSpring()) {
                    iconsScale = 1.0
                    iconsOpacity = 1.0
                }
            }
            .onDisappear {
                iconsScale = 0.8
                iconsOpacity = 0
            }

            VStack(spacing: 12) {
                Text("Get useful insights")
                    .font(PenguTheme.titleFont(28))
                    .foregroundColor(PenguTheme.darkText)
                    .multilineTextAlignment(.center)

                Text("Make better decisions with simple data.\nLet Pengu guide your perfect day.")
                    .font(PenguTheme.bodyFont(16))
                    .foregroundColor(PenguTheme.darkText.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

// MARK: - Helpers
struct ParticleEffect: Identifiable {
    let id = UUID()
    var color: Color
    var size: CGFloat
    var offsetX: CGFloat
    var offsetY: CGFloat
    var opacity: Double
}
