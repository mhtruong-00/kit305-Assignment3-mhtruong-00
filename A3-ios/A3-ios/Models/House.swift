// With support from GitHub Copilot
// Aligned with Android app (kit305-a2-mhtruong-00).
// Firestore document fields: `customerName`, `address`.
import Foundation

struct House {
    var id: String
    var name: String       // stored in Firestore as "customerName"
    var address: String

    init(id: String = "", name: String = "", address: String = "") {
        self.id = id
        self.name = name
        self.address = address
    }
}
