import SwiftUI

// MARK: - Share Customization Sheet
/// Bottom sheet for customizing and sharing a shareable card
struct ShareCustomizationSheet: View {
    let cardType: ShareableCardType
    @State private var style: ShareCardStyle
    @Environment(\.dismiss) private var dismiss

    // Cloud sharing state
    @State private var shareWithCommunity = false
    @State private var isAnonymous = true
    @State private var isSharing = false

    init(cardType: ShareableCardType, initialStyle: ShareCardStyle = .default) {
        self.cardType = cardType
        self._style = State(initialValue: initialStyle)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Live preview
                    cardPreview

                    // Theme picker
                    themePicker

                    // Toggle options
                    toggleOptions

                    // Community share option
                    communityShareOption

                    // Share buttons
                    shareButtons
                }
                .padding(Spacing.lg)
            }
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationTitle("Customize & Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.momentum.gray)
                }
            }
        }
    }

    // MARK: - Card Preview
    private var cardPreview: some View {
        ShareableCardView(cardType: cardType, style: style)
            .scaleEffect(0.5)
            .frame(height: 334) // 667 * 0.5
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .shadow(color: Color.momentum.charcoal.opacity(0.15), radius: 10, y: 5)
    }

    // MARK: - Theme Picker
    private var themePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Background Theme")
                .font(.titleSmall)
                .foregroundColor(Color.momentum.charcoal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(ShareCardStyle.BackgroundTheme.allCases) { theme in
                        ThemeButton(
                            theme: theme,
                            isSelected: style.backgroundTheme == theme,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    style.backgroundTheme = theme
                                }
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Toggle Options
    private var toggleOptions: some View {
        VStack(spacing: Spacing.sm) {
            Toggle(isOn: $style.showStats) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Color.momentum.sage)
                    Text("Show Stats")
                        .font(.bodyMedium)
                        .foregroundColor(Color.momentum.charcoal)
                }
            }
            .tint(Color.momentum.sage)

            Toggle(isOn: $style.showStreak) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color.momentum.coral)
                    Text("Show Streak")
                        .font(.bodyMedium)
                        .foregroundColor(Color.momentum.charcoal)
                }
            }
            .tint(Color.momentum.coral)

            Toggle(isOn: $style.showBranding) {
                HStack {
                    Image(systemName: "bolt.circle.fill")
                        .foregroundColor(Color.momentum.plum)
                    Text("Show Momentum Branding")
                        .font(.bodyMedium)
                        .foregroundColor(Color.momentum.charcoal)
                }
            }
            .tint(Color.momentum.plum)
        }
        .padding(Spacing.md)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    // MARK: - Community Share Option
    private var communityShareOption: some View {
        VStack(spacing: Spacing.sm) {
            Toggle(isOn: $shareWithCommunity) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(Color.momentum.sage)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Share with Community")
                            .font(.bodyMedium)
                            .foregroundColor(Color.momentum.charcoal)
                        Text("Inspire others on their journey")
                            .font(.caption)
                            .foregroundColor(Color.momentum.gray)
                    }
                }
            }
            .tint(Color.momentum.sage)

            if shareWithCommunity {
                Toggle(isOn: $isAnonymous) {
                    HStack {
                        Image(systemName: isAnonymous ? "person.fill.questionmark" : "person.fill")
                            .foregroundColor(Color.momentum.plum)
                        Text(isAnonymous ? "Share Anonymously" : "Share with Name")
                            .font(.bodySmall)
                            .foregroundColor(Color.momentum.charcoal)
                    }
                }
                .tint(Color.momentum.plum)
                .padding(.leading, Spacing.lg)
            }
        }
        .padding(Spacing.md)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    // MARK: - Share Buttons
    private var shareButtons: some View {
        VStack(spacing: Spacing.md) {
            // Main share button
            Button {
                shareExternally()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.titleSmall)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.momentum.coral)
                .clipShape(Capsule())
            }
            .disabled(isSharing)

            // Save to Photos button
            Button {
                saveToPhotos()
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Save to Photos")
                }
                .font(.bodyMedium)
                .foregroundColor(Color.momentum.charcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.momentum.cream)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.momentum.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(isSharing)
        }
    }

    // MARK: - Actions
    private func shareExternally() {
        isSharing = true

        Task { @MainActor in
            // Render the card
            let image = ShareService.shared.renderShareableCard(cardType: cardType, style: style)

            // Share to community if enabled
            if shareWithCommunity {
                await shareToCommunity()
            }

            // Present share sheet
            ShareService.shared.presentShareSheet(with: image)

            isSharing = false
            dismiss()
        }
    }

    private func saveToPhotos() {
        isSharing = true

        Task { @MainActor in
            let image = ShareService.shared.renderShareableCard(cardType: cardType, style: style)
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

            ToastManager.shared.show("Saved to Photos!", icon: "photo.fill")
            isSharing = false
        }
    }

    private func shareToCommunity() async {
        // Extract relevant data from cardType and share via CloudKit
        switch cardType {
        case .winCelebration(let description, let size, let emotion):
            let displayName = isAnonymous ? nil : UserProfileManager.shared.profile.name
            try? await CloudKitManager.shared.shareWin(
                description: description,
                size: size,
                emotion: emotion,
                displayName: displayName,
                isAnonymous: isAnonymous
            )
        default:
            // Other card types could be shared similarly
            break
        }
    }
}

// MARK: - Theme Button
struct ThemeButton: View {
    let theme: ShareCardStyle.BackgroundTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Circle()
                    .fill(theme.gradient)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: theme.icon)
                            .font(.system(size: 20))
                            .foregroundColor(theme.textColor)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.momentum.coral : Color.clear,
                                lineWidth: 3
                            )
                    )

                Text(theme.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? Color.momentum.charcoal : Color.momentum.gray)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
    }
}

// MARK: - Preview
#Preview {
    ShareCustomizationSheet(
        cardType: .dailySummary(actions: 5, wins: 2, streak: 14)
    )
}
