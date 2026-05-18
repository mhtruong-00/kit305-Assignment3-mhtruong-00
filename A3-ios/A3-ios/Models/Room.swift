// With support from GitHub Copilot
// Aligned with Android app: top-level "rooms" collection, fields:
// houseId, name, photoBase64, photoUrl
import Foundation

struct Room {
    var id: String
    var houseId: String
    var name: String
    var photoBase64: String?
    var photoUrl: String?

    init(id: String = "", houseId: String = "", name: String = "",
         photoBase64: String? = nil, photoUrl: String? = nil) {
        self.id = id
        self.houseId = houseId
        self.name = name
        self.photoBase64 = photoBase64
        self.photoUrl = photoUrl
    }
}
