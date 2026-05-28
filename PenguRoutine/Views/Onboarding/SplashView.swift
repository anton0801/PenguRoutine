import SwiftUI
import Combine
import Network

struct SplashView: View {
    
    // Phase 1 - background
    @State private var bgOpacity: Double = 0
    @State private var gradientOffset: CGFloat = -200
    
    // Phase 2 - snowflakes
    @State private var snowflakesVisible: Bool = false
    @State private var snowParticles: [SnowParticle] = SnowParticle.generate(count: 20)
    
    // Phase 3 - logo
    @State private var logoScale: CGFloat = 0.3
    @State private var networkMonitor = NWPathMonitor()
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    
    // phase: app
    @StateObject private var viewModel = PenguRoutineViewModel()
    
    // Phase 4 - exit
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0
    @State private var isVisible = true
    
    // Looping animations
    @State private var penguinBounce: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.3
    @State private var iceRingScale: CGFloat = 0.8
    @State private var iceRingOpacity: Double = 0.6
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            ZStack {
                // --- LAYER 1: Animated background gradient ---
                LinearGradient(
                    colors: [
                        Color(hex: "BAE6FD"),
                        Color(hex: "E0F2FE"),
                        Color(hex: "F0F9FF")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(1)
                .ignoresSafeArea()
                
                GeometryReader { geo in
                    Image("loadprs")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 15)
                        .opacity(0.3)
                }
                .ignoresSafeArea()
                
                NavigationLink(
                    destination: PenguRoutineWebView().navigationBarHidden(true),
                    isActive: $viewModel.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $viewModel.navigateToMain
                ) { EmptyView() }
                
                // Ice crystal top decoration
                ForEach(0..<6) { i in
                    IceCrystal(size: CGFloat.random(in: 20...45))
                        .foregroundColor(Color(hex: "38BDF8").opacity(0.15))
                        .position(
                            x: CGFloat([60, 120, 200, 260, 330, 390][i % 6]),
                            y: CGFloat([40, 80, 30, 90, 45, 70][i % 6])
                        )
                }
                
                // --- LAYER 2: Snowflakes ---
                if snowflakesVisible {
                    ForEach(snowParticles) { particle in
                        Text("❄")
                            .font(.system(size: particle.size))
                            .foregroundColor(Color(hex: "7DD3FC").opacity(particle.opacity))
                            .position(x: particle.x, y: particle.y)
                            .rotationEffect(.degrees(snowflakesVisible ? 360 : 0))
                    }
                }
                
                // --- ICE RINGS behind penguin ---
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(
                                Color(hex: "38BDF8").opacity(0.15 - Double(i) * 0.04),
                                lineWidth: 1.5
                            )
                            .frame(width: 90 + CGFloat(i) * 35, height: 90 + CGFloat(i) * 35)
                            .scaleEffect(iceRingScale + CGFloat(i) * 0.08)
                            .opacity(iceRingOpacity)
                    }
                }
                .offset(y: 20)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Ice timer icon with glow
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "38BDF8").opacity(glowPulse),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 130, height: 130)
                        
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "E0F2FE"), Color(hex: "BAE6FD")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .shadow(color: Color(hex: "38BDF8").opacity(0.4), radius: 15, x: 0, y: 5)
                            
                            // Penguin inside circle
                            PenguinView(size: 48, isAnimating: false)
                                .offset(y: penguinBounce)
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    Spacer().frame(height: 24)
                    
                    // App name
                    HStack {
                        Text("Pengu Routine")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "0F172A"))
                            .offset(y: titleOffset)
                            .opacity(titleOpacity)
                        ProgressView()
                            .tint(Color(hex: "0F172A"))
                            .opacity(titleOpacity)
                        
                    }
                    
                    Spacer().frame(height: 8)
                    
                    // Tagline
                    HStack(spacing: 6) {
                        Image(systemName: "snowflake")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Loading app content.\nWait until it's ready!")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "0EA5E9"))
                    .opacity(subtitleOpacity)
                    
                    Spacer()
                }
                
                // Bottom ice shelf
                VStack {
                    Spacer()
                    ZStack {
                        Ellipse()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "BAE6FD"), Color(hex: "93C5FD")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: UIScreen.main.bounds.width * 1.4, height: 120)
                            .offset(y: 50)
                        
                        // Snow dots on shelf
                        HStack(spacing: 16) {
                            ForEach(0..<8) { _ in
                                Circle()
                                    .fill(Color.white.opacity(0.6))
                                    .frame(width: CGFloat.random(in: 4...10), height: CGFloat.random(in: 4...10))
                            }
                        }
                        .offset(y: 20)
                    }
                    .opacity(bgOpacity)
                }
                .ignoresSafeArea()
            }
            .opacity(exitOpacity)
            .scaleEffect(exitScale)
            .onAppear { runAnimation() }
            .onDisappear {
                isVisible = false
                snowflakesVisible = false
            }
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                PenguRoutineConsentView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                ErrorApp()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func runAnimation() {
        func setupStreams() {
            NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
                .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
                .sink { data in
                    viewModel.ingestAttribution(data)
                }
                .store(in: &cancellables)
            
            NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
                .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
                .sink { data in
                    viewModel.ingestDeeplinks(data)
                }
                .store(in: &cancellables)
        }
        setupStreams()
        setupNetworkMonitoring()
        viewModel.boot()
        // Phase 1: Background (0–0.6s)
        withAnimation(.easeIn(duration: 0.6)) {
            bgOpacity = 1
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            gradientOffset = 200
        }
        
        // Phase 2: Snowflakes (0.6–1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard isVisible else { return }
            withAnimation(.easeIn(duration: 0.4)) {
                snowflakesVisible = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                iceRingScale = 1.15
                iceRingOpacity = 0.3
            }
        }
        
        // Phase 3: Logo + Title (1.4–2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = 0.55
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            guard isVisible else { return }
            withAnimation(.easeIn(duration: 0.4)) {
                subtitleOpacity = 1.0
            }
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
}

// MARK: - Supporting
struct SnowParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double

    static func generate(count: Int) -> [SnowParticle] {
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        return (0..<count).map { _ in
            SnowParticle(
                x: CGFloat.random(in: 20...w - 20),
                y: CGFloat.random(in: 0...h * 0.75),
                size: CGFloat.random(in: 8...18),
                opacity: Double.random(in: 0.3...0.8)
            )
        }
    }
}

struct IceCrystal: Shape {
    var size: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX, cy = rect.midY
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3
            let x = cx + CGFloat(cos(angle)) * size / 2
            let y = cy + CGFloat(sin(angle)) * size / 2
            if i == 0 { path.move(to: CGPoint(x: cx, y: cy)) }
            path.addLine(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: cx, y: cy))
        }
        return path
    }
}

