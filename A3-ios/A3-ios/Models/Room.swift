// With support from GitHub Copilot
import Foundation

struct Room {
    var id: String
    var houseId: String
    var name: String
    var createdAt: Date

    init(id: String = "", houseId: String = "", name: String = "", createdAt: Date = Date()) {
        self.id = id
        self.houseId = houseId
        self.name = name
        self.createdAt = createdAt
    }
}
