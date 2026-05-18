// With support from GitHub Copilot
// Aligned with Android app: top-level "floorspaces" collection.
// Firestore fields: roomId, name, widthMm (Int), depthMm (Int),
//   selectedProductId, selectedProductName, selectedProductVariant,
//   photoBase64
import Foundation

struct FloorSpace {
    var id: String
    var roomId: String
    var name: String
    var widthMm: Int
    var depthMm: Int
    var selectedProductId: String
    var selectedProductName: String
    var selectedProductVariant: String
    var photoBase64: String?

    var areaSqm: Double {
        return (Double(widthMm) / 1000.0) * (Double(depthMm) / 1000.0)
    }

    init(id: String = "", roomId: String = "", name: String = "",
         widthMm: Int = 0, depthMm: Int = 0,
         selectedProductId: String = "", selectedProductName: String = "",
         selectedProductVariant: String = "",
         photoBase64: String? = nil) {
        self.id = id
        self.roomId = roomId
        self.name = name
        self.widthMm = widthMm
        self.depthMm = depthMm
        self.selectedProductId = selectedProductId
        self.selectedProductName = selectedProductName
        self.selectedProductVariant = selectedProductVariant
        self.photoBase64 = photoBase64
    }
}
