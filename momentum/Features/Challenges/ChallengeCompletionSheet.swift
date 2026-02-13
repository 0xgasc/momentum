import SwiftUI
import SwiftData

// MARK: - Challenge Completion Sheet
struct ChallengeCompletionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let challenge: Challenge
    let onComplete: () -> Void

    // Form state
    @State private var notes: String = ""
    @State private var emotion: Int = 3
    @State private var photoData: Data?
    @State private var voiceMemoPath: String?
    @State private var showMediaSection = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Challenge header
                    ChallengeCompletionHeader(challenge: challenge)

                    // Notes field (optional)
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("How did it go?")
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)

                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Reflect on your experience... (optional)")
                                    .font(.bodyMedium)
                                    .foregroundColor(Color.momentum.gray.opacity(0.6))
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.sm + 2)
                            }

                            TextEditor(text: $notes)
                                .font(.bodyMedium)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .padding(Spacing.xs)
                                .background(Color.momentum.cream)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                        }
                    }

                    // Emotion selector (reused from WinCard)
                    EmotionSelector(selectedEmotion: $emotion)

                    // Media section (collapsible, optional)
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showMediaSection.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Add a memory")
                                    .font(.titleSmall)
                                    .foregroundColor(Color.momentum.charcoal)

                                Text("(optional)")
                                    .font(.bodySmall)
                                    .foregroundColor(Color.momentum.gray)

                                Spacer()

                                Image(systemName: showMediaSection ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)
                            }
                        }

                        if showMediaSection {
                            HStack(spacing: Spacing.md) {
                                CompactPhotoPicker(photoData: $photoData)
                                VoiceMemoRecorderView(voiceMemoPath: $voiceMemoPath)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.momentum.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                    Spacer().frame(height: Spacing.md)

                    // Complete button
                    Button(action: completeChallenge) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Challenge")
                        }
                        .font(.titleSmall)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.momentum.coral)
                        .clipShape(Capsule())
                    }

                    // Quick complete option
                    Button {
                        quickComplete()
                    } label: {
                        Text("Skip reflection, just complete")
                            .font(.bodySmall)
                            .foregroundColor(Color.momentum.gray)
                    }
                    .padding(.bottom, Spacing.lg)
                }
                .padding(Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationTitle("Complete Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.momentum.gray)
                }
            }
        }
    }

    private func completeChallenge() {
        // Save reflection data to challenge
        challenge.completionNotes = notes.isEmpty ? nil : notes
        challenge.completionEmotion = emotion
        challenge.completionPhotoData = photoData
        challenge.voiceMemoPath = voiceMemoPath

        // Mark complete
        challenge.isCompleted = true
        challenge.completedAt = Date()

        // Auto-create Win
        createWinFromChallenge()

        try? modelContext.save()

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Show toast
        ToastManager.shared.show("Challenge completed!", icon: "trophy.fill")

        // Award XP and check badges
        onComplete()

        dismiss()
    }

    private func quickComplete() {
        challenge.isCompleted = true
        challenge.completedAt = Date()
        challenge.completionEmotion = 3 // Default neutral

        // Still auto-create basic Win
        createWinFromChallenge()

        try? modelContext.save()

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Show toast
        ToastManager.shared.show("Challenge completed!", icon: "trophy.fill")

        onComplete()

        dismiss()
    }

    private func createWinFromChallenge() {
        let winDescription = notes.isEmpty
            ? "Completed: \(challenge.title)"
            : notes

        let win = Win(
            description: winDescription,
            size: challenge.correspondingWinSize,
            emotion: emotion
        )
        modelContext.insert(win)
    }
}

// MARK: - Challenge Completion Header
struct ChallengeCompletionHeader: View {
    let challenge: Challenge

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Category icon with celebration background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                challenge.category.color.opacity(0.3),
                                challenge.category.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: challenge.category.icon)
                    .font(.system(size: 36))
                    .foregroundColor(challenge.category.color)
            }

            VStack(spacing: Spacing.xs) {
                Text(challenge.title)
                    .font(.titleMedium)
                    .foregroundColor(Color.momentum.charcoal)
                    .multilineTextAlignment(.center)

                HStack(spacing: Spacing.md) {
                    // Difficulty badge
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                        Text(challenge.difficulty.rawValue)
                            .font(.caption)
                    }
                    .foregroundColor(challenge.difficulty.color)

                    // XP reward
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("+\(challenge.xpReward) XP")
                            .font(.caption)
                    }
                    .foregroundColor(Color.momentum.gold)

                    // Win size indicator
                    HStack(spacing: 4) {
                        Image(systemName: challenge.correspondingWinSize.icon)
                            .font(.system(size: 12))
                        Text(challenge.correspondingWinSize.displayName + " Win")
                            .font(.caption)
                    }
                    .foregroundColor(challenge.correspondingWinSize.color)
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    challenge.category.color.opacity(0.1),
                    Color.momentum.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

#Preview {
    ChallengeCompletionSheet(
        challenge: Challenge(
            title: "Morning Manifestation",
            description: "Write down 3 things you're grateful for before 9am",
            category: .mindset,
            difficulty: .medium,
            duration: .daily,
            xpReward: 75
        ),
        onComplete: {}
    )
}
