import SwiftUI

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let rotationSpeed: Double
    let fallSpeed: CGFloat
    let horizontalDrift: CGFloat
    let shape: ConfettiShape

    enum ConfettiShape: CaseIterable {
        case circle
        case rectangle
        case triangle
    }
}

struct ConfettiView: View {
    let intensity: Int
    @Binding var isActive: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var animationProgress: CGFloat = 0

    private let colors = Color.momentum.confettiColors

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiParticleView(particle: particle, progress: animationProgress)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startConfetti(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func startConfetti(in size: CGSize) {
        particles = (0..<intensity).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: colors.randomElement() ?? Color.momentum.coral,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -360...360),
                fallSpeed: CGFloat.random(in: 200...400),
                horizontalDrift: CGFloat.random(in: -50...50),
                shape: ConfettiParticle.ConfettiShape.allCases.randomElement() ?? .circle
            )
        }

        animationProgress = 0

        withAnimation(.easeOut(duration: 3)) {
            animationProgress = 1
        }

        // Haptic feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            isActive = false
            particles = []
        }
    }
}

struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    let progress: CGFloat

    var body: some View {
        shapeView
            .frame(width: particle.size, height: particle.size * shapeMultiplier)
            .foregroundColor(particle.color)
            .rotationEffect(.degrees(particle.rotation + particle.rotationSpeed * Double(progress)))
            .position(
                x: particle.x + particle.horizontalDrift * progress,
                y: particle.y + particle.fallSpeed * progress * 2
            )
            .opacity(1.0 - Double(progress) * 0.5)
    }

    private var shapeMultiplier: CGFloat {
        switch particle.shape {
        case .circle: return 1
        case .rectangle: return 1.5
        case .triangle: return 1
        }
    }

    @ViewBuilder
    private var shapeView: some View {
        switch particle.shape {
        case .circle:
            Circle()
        case .rectangle:
            RoundedRectangle(cornerRadius: 2)
        case .triangle:
            Triangle()
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Confetti Modifier
struct ConfettiModifier: ViewModifier {
    @Binding var isShowing: Bool
    let intensity: Int

    func body(content: Content) -> some View {
        content
            .overlay(
                ConfettiView(intensity: intensity, isActive: $isShowing)
            )
    }
}

extension View {
    func confetti(isShowing: Binding<Bool>, intensity: Int = 100) -> some View {
        modifier(ConfettiModifier(isShowing: isShowing, intensity: intensity))
    }
}

// MARK: - Celebration View
struct CelebrationView: View {
    let message: String
    let winSize: WinSize
    @Binding var isShowing: Bool
    var onShare: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }

            VStack(spacing: Spacing.lg) {
                Image(systemName: winSize.icon)
                    .font(.system(size: 60))
                    .foregroundColor(winSize.color)

                Text(message)
                    .font(.displayMedium)
                    .foregroundColor(Color.momentum.charcoal)
                    .multilineTextAlignment(.center)

                HStack(spacing: Spacing.md) {
                    MomentumButton("Nice!", icon: "hand.thumbsup.fill") {
                        withAnimation {
                            isShowing = false
                        }
                    }

                    if onShare != nil {
                        Button {
                            withAnimation {
                                isShowing = false
                            }
                            onShare?()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.titleSmall)
                                .foregroundColor(Color.momentum.coral)
                                .frame(width: 48, height: 48)
                                .background(Color.momentum.coral.opacity(0.12))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(Spacing.xl)
            .background(Color.momentum.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.modal))
            .momentumShadow(radius: 20)
            .padding(Spacing.xl)
        }
        .confetti(isShowing: $isShowing, intensity: winSize.confettiIntensity)
    }
}

#Preview {
    @Previewable @State var showConfetti = true

    ZStack {
        Color.momentum.cream
            .ignoresSafeArea()

        CelebrationView(
            message: "Look at you, making moves.",
            winSize: .medium,
            isShowing: $showConfetti
        )
    }
}
