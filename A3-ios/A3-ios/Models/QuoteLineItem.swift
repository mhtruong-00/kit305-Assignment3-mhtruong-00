// With support from GitHub Copilot
// Quote-line model aligned with the Android quote screen.
// Pricing now comes from a product-rate map (from API) with sensible defaults,
// not a per-item pricePerSqm value, and rooms add a labour charge ($200) when
// they have at least one measured + included item.
import Foundation

enum QuoteItemType {
    case window
    case floor
}

struct QuoteLineItem {
    var id: String           // stable item id (Firestore doc id or composite)
    var roomId: String
    var roomName: String
    var itemType: QuoteItemType
    var itemName: String
    var productId: String
    var productName: String
    var variantName: String
    var widthMm: Int
    var heightOrDepthMm: Int
    var panelCount: Int
    var pricePerSqm: Double
    var isIncluded: Bool

    var areaSqm: Double {
        return (Double(widthMm) / 1000.0) * (Double(heightOrDepthMm) / 1000.0)
    }

    var itemPrice: Double {
        return pricePerSqm * areaSqm
    }

    var typeLabel: String {
        return itemType == .window ? "Window" : "Floor"
    }

    var dimensionLabel: String {
        let suffix = itemType == .window ? "H" : "D"
        return "\(widthMm)W × \(heightOrDepthMm)\(suffix) mm"
    }

    var priceLabel: String {
        return String(format: "$%.2f", itemPrice)
    }

    init(id: String = "", roomId: String = "", roomName: String = "",
         itemType: QuoteItemType = .window, itemName: String = "",
         productId: String = "", productName: String = "", variantName: String = "",
         widthMm: Int = 0, heightOrDepthMm: Int = 0,
         panelCount: Int = 1, pricePerSqm: Double = 0, isIncluded: Bool = true) {
        self.id = id
        self.roomId = roomId
        self.roomName = roomName
        self.itemType = itemType
        self.itemName = itemName
        self.productId = productId
        self.productName = productName
        self.variantName = variantName
        self.widthMm = widthMm
        self.heightOrDepthMm = heightOrDepthMm
        self.panelCount = panelCount
        self.pricePerSqm = pricePerSqm
        self.isIncluded = isIncluded
    }
}
