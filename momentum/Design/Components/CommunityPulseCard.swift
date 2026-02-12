import SwiftUI

/// Shows community stats to make users feel they're not alone
struct CommunityPulseCard: View {
    @ObservedObject private var cloudKit = CloudKitManager.shared
    @EnvironmentObject private var purchaseService: PurchaseService

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header - always visible, tappable
            Button {
                withAnimation(.spring(response: 0.4)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color.momentum.sage)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(Color.momentum.sage.opacity(0.3))
                                    .frame(width: 16, height: 16)
                            )

                        Text("Live Community")
                            .font(.caption)
                            .foregroundColor(Color.momentum.sage)
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }

                    Spacer()

                    HStack(spacing: Spacing.sm) {
                        Text("\(cloudKit.activeUsersCount) active")
                            .font(.caption)
                            .foregroundColor(Color.momentum.gray)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(Color.momentum.gray)
                    }
                }
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Main stat
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            Text("\(cloudKit.activeUsersCount)")
                                .font(.displayLarge)
                                .foregroundColor(Color.momentum.charcoal)

                            Text("people building momentum with you")
                                .font(.bodySmall)
                                .foregroundColor(Color.momentum.gray)
                        }
                    }

                    // Secondary stats
                    HStack(spacing: Spacing.lg) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.momentum.gold)

                            Text("\(cloudKit.winsToday) wins today")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }

                        if cloudKit.streakUsersCount > 0 {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.momentum.coral)

                                Text("\(cloudKit.streakUsersCount) on a streak too")
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)
                            }
                        }
                    }

                    // CTA
                    if purchaseService.isPlus {
                        NavigationLink(destination: CommunityFeedView()) {
                            HStack {
                                Text("See what others are celebrating")
                                    .font(.bodySmall)
                                    .foregroundColor(Color.momentum.plum)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.momentum.plum)
                            }
                        }
                    } else {
                        Button {
                            purchaseService.showPaywall = true
                        } label: {
                            HStack {
                                Text("Upgrade to join the community")
                                    .font(.bodySmall)
                                    .foregroundColor(Color.momentum.coral)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.momentum.coral)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.md)
        .background(
            LinearGradient(
                colors: [
                    Color.momentum.sage.opacity(0.08),
                    Color.momentum.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(Color.momentum.sage.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            Task {
                await cloudKit.refreshCommunityStats()
            }
        }
    }
}

#Preview {
    CommunityPulseCard()
        .padding()
        .background(Color.momentum.cream)
        .environmentObject(PurchaseService())
}
