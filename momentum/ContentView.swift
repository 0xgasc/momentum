import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @EnvironmentObject private var purchaseService: PurchaseService

    enum Tab: Int, CaseIterable {
        case home
        case goals
        case challenges
        case wins
        case people

        var title: String {
            switch self {
            case .home: return "Home"
            case .goals: return "Goals"
            case .challenges: return "Challenges"
            case .wins: return "Wins"
            case .people: return "People"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .goals: return "target"
            case .challenges: return "flame.fill"
            case .wins: return "trophy.fill"
            case .people: return "person.2.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            GoalsView()
                .tabItem {
                    Label(Tab.goals.title, systemImage: Tab.goals.icon)
                }
                .tag(Tab.goals)

            ChallengesView()
                .tabItem {
                    Label(Tab.challenges.title, systemImage: Tab.challenges.icon)
                }
                .tag(Tab.challenges)

            WinsView()
                .tabItem {
                    Label(Tab.wins.title, systemImage: Tab.wins.icon)
                }
                .tag(Tab.wins)

            RelationshipsView()
                .tabItem {
                    Label(Tab.people.title, systemImage: Tab.people.icon)
                }
                .tag(Tab.people)
        }
        .tint(Color.momentum.coral)
        .sheet(isPresented: $purchaseService.showPaywall) {
            PaywallView()
                .environmentObject(purchaseService)
        }
    }
}

// MARK: - Custom Tab Bar (Optional Premium Style)
struct MomentumTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    let tabs: [ContentView.Tab]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.rawValue) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.lg)
        .background(
            Color.momentum.white
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            Rectangle()
                .fill(Color.momentum.gray.opacity(0.1))
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct TabButton: View {
    let tab: ContentView.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: tab.icon)
                    .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.momentum.coral : Color.momentum.gray)

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? Color.momentum.coral : Color.momentum.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .background(
                isSelected
                    ? Color.momentum.coral.opacity(0.1)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseService())
}
