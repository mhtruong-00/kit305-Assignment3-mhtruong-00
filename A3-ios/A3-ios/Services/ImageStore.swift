// With support from GitHub Copilot
// Compress and encode UIImages to base64 JPEGs sized for Firestore storage,
// matching the Android RoomDetails encoding behaviour (target < 250 KB).
import UIKit

class ImageStore {
    static let shared = ImageStore()
    private init() {}

    /// Roughly the Android RoomDetails budget: keep raw JPEG bytes comfortably
    /// under the Firestore single-field limit once base64 expansion is applied.
    private let maxBytes: Int = 250_000
    /// Largest edge in pixels — keeps memory and upload size predictable.
    private let maxDimension: CGFloat = 1280

    /// Compress + downscale `image` to a base64 JPEG string suitable for Firestore.
    /// Iteratively lowers JPEG quality (down to 0.25) until the encoded payload
    /// fits within the size budget.
    func encodeImage(_ image: UIImage, compressionQuality: CGFloat = 0.85) -> String? {
        let scaled = downscale(image)
        var quality = compressionQuality
        guard var data = scaled.jpegData(compressionQuality: quality) else { return nil }
        while data.count > maxBytes && quality > 0.25 {
            quality -= 0.10
            guard let next = scaled.jpegData(compressionQuality: quality) else { break }
            data = next
        }
        return data.base64EncodedString()
    }

    /// Decode a base64 JPEG string back to a `UIImage`.
    func decodeImage(_ base64String: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Helpers

    private func downscale(_ image: UIImage) -> UIImage {
        let largest = max(image.size.width, image.size.height)
        guard largest > maxDimension else { return image }
        let scale = maxDimension / largest
        let newSize = CGSize(width: image.size.width * scale,
                             height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
