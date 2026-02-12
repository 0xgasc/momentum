import SwiftUI

struct WinCard: View {
    let win: Win

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                // Size indicator
                Image(systemName: win.size.icon)
                    .font(.system(size: 20))
                    .foregroundColor(win.size.color)

                Spacer()

                // Emotion
                Text(win.emotionEmoji)
                    .font(.system(size: 24))
            }

            Text(win.winDescription)
                .font(.bodyMedium)
                .foregroundColor(Color.momentum.charcoal)
                .lineLimit(3)

            HStack {
                if let goal = win.goal {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: goal.category.icon)
                            .font(.system(size: 10))
                        Text(goal.title)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundColor(goal.category.color)
                }

                Spacer()

                Text(win.formattedDate)
                    .font(.caption)
                    .foregroundColor(Color.momentum.gray)
            }
        }
        .padding(Spacing.md)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow(radius: 4)
    }
}

// MARK: - Win Size Selector
struct WinSizeSelector: View {
    @Binding var selectedSize: WinSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("How big was this win?")
                .font(.titleSmall)
                .foregroundColor(Color.momentum.charcoal)

            HStack(spacing: Spacing.xs) {
                ForEach(WinSize.allCases) { size in
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        selectedSize = size
                    }) {
                        VStack(spacing: Spacing.xxs) {
                            Image(systemName: size.icon)
                                .font(.system(size: 20))
                            Text(size.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(selectedSize == size ? size.color : Color.momentum.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            selectedSize == size
                                ? size.color.opacity(0.15)
                                : Color.momentum.cream
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                    }
                }
            }
        }
    }
}

// MARK: - Emotion Selector
struct EmotionSelector: View {
    @Binding var selectedEmotion: Int

    private let emotions = [
        (1, "😊", "Good"),
        (2, "😄", "Great"),
        (3, "🥳", "Amazing"),
        (4, "🔥", "On Fire"),
        (5, "🚀", "Unstoppable")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("How are you feeling?")
                .font(.titleSmall)
                .foregroundColor(Color.momentum.charcoal)

            HStack(spacing: Spacing.xs) {
                ForEach(emotions, id: \.0) { emotion in
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        selectedEmotion = emotion.0
                    }) {
                        VStack(spacing: Spacing.xxs) {
                            Text(emotion.1)
                                .font(.system(size: 28))
                            Text(emotion.2)
                                .font(.caption)
                                .foregroundColor(
                                    selectedEmotion == emotion.0
                                        ? Color.momentum.coral
                                        : Color.momentum.gray
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            selectedEmotion == emotion.0
                                ? Color.momentum.coral.opacity(0.1)
                                : Color.momentum.cream
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WinCard(win: Win(
            description: "Finally shipped the new feature after 2 weeks of work!",
            size: .big,
            emotion: 4
        ))

        WinSizeSelector(selectedSize: .constant(.medium))

        EmotionSelector(selectedEmotion: .constant(3))
    }
    .padding()
    .background(Color.momentum.cream)
}
