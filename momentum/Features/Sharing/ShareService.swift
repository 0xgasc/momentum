import SwiftUI
import UIKit

// MARK: - Share Service
/// Handles rendering SwiftUI views to images and presenting the iOS share sheet
@MainActor
class ShareService {
    static let shared = ShareService()

    private init() {}

    // MARK: - Image Rendering

    /// Renders a SwiftUI view to a UIImage using ImageRenderer (iOS 16+)
    func renderToImage<V: View>(_ view: V, size: CGSize = CGSize(width: 375, height: 667)) -> UIImage {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = UIScreen.main.scale

        // High quality rendering
        renderer.proposedSize = ProposedViewSize(size)

        return renderer.uiImage ?? UIImage()
    }

    /// Renders a shareable card to image
    func renderShareableCard(cardType: ShareableCardType, style: ShareCardStyle) -> UIImage {
        let view = ShareableCardView(cardType: cardType, style: style)
        return renderToImage(view, size: CGSize(width: 375, height: 667))
    }

    // MARK: - Share Sheet

    /// Presents iOS share sheet with the given image
    func presentShareSheet(with image: UIImage, from sourceView: UIView? = nil) {
        let activityItems: [Any] = [image]

        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // Exclude some activity types that don't make sense for images
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]

        // Find the topmost view controller to present from
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            // iPad requires popover presentation
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = sourceView ?? topVC.view
                popover.sourceRect = sourceView?.bounds ?? CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = .any
            }

            topVC.present(activityVC, animated: true)
        }
    }

    /// Presents share sheet with rendered shareable card
    func shareCard(cardType: ShareableCardType, style: ShareCardStyle, from sourceView: UIView? = nil) {
        let image = renderShareableCard(cardType: cardType, style: style)
        presentShareSheet(with: image, from: sourceView)
    }
}

// MARK: - Weekly Stats
/// Stats for weekly recap card
struct WeeklyStats {
    let actionsCompleted: Int
    let winsLogged: Int
    let challengesCompleted: Int
    let currentStreak: Int
    let topCategory: String?

    static var empty: WeeklyStats {
        WeeklyStats(
            actionsCompleted: 0,
            winsLogged: 0,
            challengesCompleted: 0,
            currentStreak: 0,
            topCategory: nil
        )
    }
}
