// With support from GitHub Copilot
import Foundation

enum QuoteItemType {
    case window
    case floor
}

struct QuoteLineItem {
    var id: String
    var roomName: String
    var itemType: QuoteItemType
    var productName: String
    var variantName: String
    var widthCm: Double
    var heightOrLengthCm: Double
    var pricePerSqm: Double
    var isIncluded: Bool

    var areaSqm: Double {
        return (widthCm / 100.0) * (heightOrLengthCm / 100.0)
    }

    var itemPrice: Double {
        return pricePerSqm * areaSqm
    }

    var typeLabel: String {
        return itemType == .window ? "Window" : "Floor"
    }

    var dimensionLabel: String {
        let secondLabel = itemType == .window ? "H" : "L"
        return "\(Int(widthCm))W × \(Int(heightOrLengthCm))\(secondLabel) cm"
    }

    var priceLabel: String {
        return String(format: "$%.2f", itemPrice)
    }

    init(id: String = "", roomName: String = "", itemType: QuoteItemType = .window,
         productName: String = "", variantName: String = "",
         widthCm: Double = 0, heightOrLengthCm: Double = 0,
         pricePerSqm: Double = 0, isIncluded: Bool = true) {
        self.id = id
        self.roomName = roomName
        self.itemType = itemType
        self.productName = productName
        self.variantName = variantName
        self.widthCm = widthCm
        self.heightOrLengthCm = heightOrLengthCm
        self.pricePerSqm = pricePerSqm
        self.isIncluded = isIncluded
    }
}
