import SwiftUI
import PhotosUI

/// A photo picker component for adding photos to challenge completions
struct PhotoPickerView: View {
    @Binding var photoData: Data?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: Spacing.sm) {
            if let photoData = photoData,
               let uiImage = UIImage(data: photoData) {
                // Show selected photo with remove button
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))

                    Button {
                        withAnimation {
                            self.photoData = nil
                            self.selectedItem = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 24, height: 24)
                            )
                    }
                    .offset(x: 6, y: -6)
                }
            } else {
                // Show photo picker button
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: Spacing.xs) {
                        ZStack {
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .fill(Color.momentum.cream)
                                .frame(width: 120, height: 120)

                            VStack(spacing: Spacing.xs) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.momentum.sage)

                                Text("Add Photo")
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)
                            }
                        }
                    }
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            // Compress the image to save space
                            if let uiImage = UIImage(data: data),
                               let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                                await MainActor.run {
                                    withAnimation {
                                        self.photoData = compressed
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Compact Photo Picker (for inline use)

struct CompactPhotoPicker: View {
    @Binding var photoData: Data?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let photoData = photoData,
               let uiImage = UIImage(data: photoData) {
                // Show thumbnail
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))

                Button {
                    withAnimation {
                        self.photoData = nil
                        self.selectedItem = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.momentum.gray)
                }
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.momentum.sage)

                        Text("Photo")
                            .font(.bodySmall)
                            .foregroundColor(Color.momentum.charcoal)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.momentum.cream)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data),
                               let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                                await MainActor.run {
                                    withAnimation {
                                        self.photoData = compressed
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        PhotoPickerView(photoData: .constant(nil))

        CompactPhotoPicker(photoData: .constant(nil))
    }
    .padding()
    .background(Color.momentum.white)
}
