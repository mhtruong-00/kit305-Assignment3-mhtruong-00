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

    init(id: String = "", name: String = "", description: String = "",
         category: String = "", imageUrl: String? = nil,
         pricePerSqm: Double = 0, variants: [ProductVariant] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.imageUrl = imageUrl
        self.pricePerSqm = pricePerSqm
        self.variants = variants
    }
}
