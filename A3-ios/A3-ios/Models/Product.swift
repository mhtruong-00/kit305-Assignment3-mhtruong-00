// With support from GitHub Copilot
import Foundation

struct ProductVariant {
    var id: String
    var name: String

    init(id: String = "", name: String = "") {
        self.id = id
        self.name = name
    }
}

struct Product {
    var id: String
    var name: String
    var description: String
    var category: String   // "window" or "floor"
    var imageUrl: String?
    var pricePerSqm: Double
    var variants: [ProductVariant]
    var minWidth: Int
    var maxWidth: Int
    var minHeight: Int
    var maxHeight: Int
    var maxPanelCount: Int

    init(id: String = "", name: String = "", description: String = "",
         category: String = "", imageUrl: String? = nil,
         pricePerSqm: Double = 0, variants: [ProductVariant] = [],
         minWidth: Int = 0, maxWidth: Int = 9999,
         minHeight: Int = 0, maxHeight: Int = 9999,
         maxPanelCount: Int = 1) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.imageUrl = imageUrl
        self.pricePerSqm = pricePerSqm
        self.variants = variants
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.maxPanelCount = maxPanelCount
    }
}
