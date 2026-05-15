// With support from GitHub Copilot
import Foundation

struct FloorSpace {
    var id: String
    var roomId: String
    var widthCm: Double
    var lengthCm: Double
    var productId: String
    var variantId: String
    var productName: String
    var variantName: String
    var pricePerSqm: Double
    var photoBase64: String?

    var areaSqm: Double {
        return (widthCm / 100.0) * (lengthCm / 100.0)
    }

    var itemPrice: Double {
        return pricePerSqm * areaSqm
    }

    var displayLabel: String {
        let prodStr = productName.isEmpty ? "No product" : productName
        let varStr = variantName.isEmpty ? "" : " – \(variantName)"
        return "\(widthCm)×\(lengthCm)cm  \(prodStr)\(varStr)"
    }

    init(id: String = "", roomId: String = "", widthCm: Double = 0, lengthCm: Double = 0,
         productId: String = "", variantId: String = "", productName: String = "",
         variantName: String = "", pricePerSqm: Double = 0, photoBase64: String? = nil) {
        self.id = id
        self.roomId = roomId
        self.widthCm = widthCm
        self.lengthCm = lengthCm
        self.productId = productId
        self.variantId = variantId
        self.productName = productName
        self.variantName = variantName
        self.pricePerSqm = pricePerSqm
        self.photoBase64 = photoBase64
    }
}
