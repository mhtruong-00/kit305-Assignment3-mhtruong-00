// With support from GitHub Copilot
import UIKit

class ImageStore {
    static let shared = ImageStore()
    private init() {}

    // Compress and encode UIImage to a base64 JPEG string for Firestore storage
    func encodeImage(_ image: UIImage, compressionQuality: CGFloat = 0.5) -> String? {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else { return nil }
        return data.base64EncodedString()
    }

    // Decode a base64 JPEG string back to a UIImage
    func decodeImage(_ base64String: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        return UIImage(data: data)
    }
}
