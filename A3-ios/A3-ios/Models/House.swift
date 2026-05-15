// With support from GitHub Copilot
import Foundation

struct House {
    var id: String
    var name: String
    var address: String
    var createdAt: Date

    init(id: String = "", name: String = "", address: String = "", createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.address = address
        self.createdAt = createdAt
    }
}
