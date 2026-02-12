import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sparkles",
            title: "Welcome to momentum",
            subtitle: "From One Day to Day One",
            description: "Turn your someday goals into today's actions. We're here to help you bridge the gap between inspiration and execution."
        ),
        OnboardingPage(
            icon: "target",
            title: "Set Meaningful Goals",
            subtitle: "Dream big, start small",
            description: "Create goals across adventure, career, wealth, relationships, and more. Each goal breaks down into bite-sized micro-actions."
        ),
        OnboardingPage(
            icon: "checkmark.circle.fill",
            title: "Take Micro-Actions",
            subtitle: "Progress, not perfection",
            description: "Small daily actions compound into massive results. Research, connect, reflect, create, and do — one step at a time."
        ),
        OnboardingPage(
            icon: "trophy.fill",
            title: "Celebrate Your Wins",
            subtitle: "You deserve this",
            description: "Log every win, big or small. Watch your confidence grow as you build a record of your achievements."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page indicators
            HStack(spacing: Spacing.xs) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.momentum.coral : Color.momentum.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, Spacing.lg)

            // Action button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Continue" : "Let's Go")
                    .font(.titleMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.momentum.coral)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.md)

            // Skip button (only show if not on last page)
            if currentPage < pages.count - 1 {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Skip")
                        .font(.bodyMedium)
                        .foregroundColor(Color.momentum.gray)
                }
                .padding(.bottom, Spacing.lg)
            } else {
                // Spacer for consistent layout
                Text(" ")
                    .font(.bodyMedium)
                    .padding(.bottom, Spacing.lg)
            }
        }
        .background(Color.momentum.cream)
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
}

// MARK: - Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.momentum.coral.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundColor(Color.momentum.coral)
            }
            .padding(.bottom, Spacing.lg)

            // Title
            Text(page.title)
                .font(.displayLarge)
                .foregroundColor(Color.momentum.charcoal)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(page.subtitle)
                .font(.titleMedium)
                .foregroundColor(Color.momentum.coral)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.bodyLarge)
                .foregroundColor(Color.momentum.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
