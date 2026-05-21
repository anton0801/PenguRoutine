import SwiftUI

struct PenguTheme {
    // MARK: - Ice Colors
    static let iceBg = Color(hex: "E0F2FE")
    static let iceMid = Color(hex: "BAE6FD")
    static let snow = Color.white
    static let iceBlue = Color(hex: "38BDF8")
    static let activeBlue = Color(hex: "0EA5E9")
    static let iceGlow = Color(hex: "22D3EE")
    static let darkText = Color(hex: "0F172A")
    static let coldBlue = Color(hex: "60A5FA")

    // MARK: - State Colors
    static let stateCold = Color(hex: "60A5FA")
    static let stateNormal = Color(hex: "22C55E")
    static let stateHappy = Color(hex: "FACC15")
    static let stateMiss = Color(hex: "EF4444")

    // MARK: - Gradients
    static let skyGradient = LinearGradient(
        colors: [Color(hex: "E0F2FE"), Color(hex: "BAE6FD"), Color(hex: "93C5FD")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let iceGradient = LinearGradient(
        colors: [Color(hex: "38BDF8"), Color(hex: "22D3EE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let deepIceGradient = LinearGradient(
        colors: [Color(hex: "0EA5E9"), Color(hex: "38BDF8")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.9), Color.white.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Shadows
    static func iceShadow(_ opacity: Double = 0.2) -> Color {
        Color(hex: "7DD3FC").opacity(opacity)
    }

    // MARK: - Fonts
    static func titleFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func bodyFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func captionFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    // MARK: - Spacing
    static let cardPadding: CGFloat = 16
    static let horizontalPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 20
    static let cardRadius: CGFloat = 16

    // MARK: - Animations
    static func spring() -> Animation {
        .spring(response: 0.4, dampingFraction: 0.7)
    }

    static func slowSpring() -> Animation {
        .spring(response: 0.6, dampingFraction: 0.8)
    }
}

// MARK: - View Modifiers
struct IceCardStyle: ViewModifier {
    var padding: CGFloat = PenguTheme.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: PenguTheme.cardRadius)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: PenguTheme.iceShadow(0.25), radius: 12, x: 0, y: 4)
            )
    }
}

extension View {
    func iceCard(padding: CGFloat = PenguTheme.cardPadding) -> some View {
        modifier(IceCardStyle(padding: padding))
    }
}

// MARK: - Penguin Component
struct PenguinView: View {
    var size: CGFloat = 60
    var isAnimating: Bool = false
    @State private var bounce: CGFloat = 0
    @State private var eyeBlink: Bool = false

    var body: some View {
        ZStack {
            // Body
            Ellipse()
                .fill(Color(hex: "1E293B"))
                .frame(width: size * 0.7, height: size)

            // White belly
            Ellipse()
                .fill(Color.white)
                .frame(width: size * 0.45, height: size * 0.65)
                .offset(y: size * 0.05)

            // Eyes
            HStack(spacing: size * 0.12) {
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.14, height: eyeBlink ? size * 0.02 : size * 0.14)
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.14, height: eyeBlink ? size * 0.02 : size * 0.14)
            }
            .offset(y: -size * 0.18)

            // Beak
            Triangle()
                .fill(Color(hex: "F97316"))
                .frame(width: size * 0.15, height: size * 0.1)
                .offset(y: -size * 0.08)

            // Feet
            HStack(spacing: size * 0.15) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "F97316"))
                    .frame(width: size * 0.18, height: size * 0.1)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "F97316"))
                    .frame(width: size * 0.18, height: size * 0.1)
            }
            .offset(y: size * 0.5)
        }
        .offset(y: bounce)
        .onAppear {
            if isAnimating {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    bounce = -8
                }
                Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        eyeBlink = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            eyeBlink = false
                        }
                    }
                }
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
