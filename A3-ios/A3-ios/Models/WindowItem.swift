// With support from GitHub Copilot
// Aligned with Android app: top-level "windows" collection.
// Firestore fields: roomId, name, widthMm (Int), heightMm (Int),
//   selectedProductId, selectedProductName, selectedProductVariant,
//   panelCount, photoBase64
import Foundation

struct WindowItem {
    var id: String
    var roomId: String
    var name: String
    var widthMm: Int
    var heightMm: Int
    var selectedProductId: String
    var selectedProductName: String
    var selectedProductVariant: String
    var panelCount: Int
    var photoBase64: String?

    /// Area in m² derived from millimetres.
    var areaSqm: Double {
        return (Double(widthMm) / 1000.0) * (Double(heightMm) / 1000.0)
    }

    init(id: String = "", roomId: String = "", name: String = "",
         widthMm: Int = 0, heightMm: Int = 0,
         selectedProductId: String = "", selectedProductName: String = "",
         selectedProductVariant: String = "",
         panelCount: Int = 1, photoBase64: String? = nil) {
        self.id = id
        self.roomId = roomId
        self.name = name
        self.widthMm = widthMm
        self.heightMm = heightMm
        self.selectedProductId = selectedProductId
        self.selectedProductName = selectedProductName
        self.selectedProductVariant = selectedProductVariant
        self.panelCount = panelCount
        self.photoBase64 = photoBase64
    }
}
