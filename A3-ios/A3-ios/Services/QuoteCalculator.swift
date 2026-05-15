// With support from GitHub Copilot
import Foundation

class QuoteCalculator {
    static let shared = QuoteCalculator()
    private init() {}

    func buildLineItems(rooms: [Room],
                        windowsByRoom: [String: [WindowItem]],
                        floorsByRoom: [String: [FloorSpace]]) -> [QuoteLineItem] {
        var items: [QuoteLineItem] = []

        for room in rooms {
            if let windows = windowsByRoom[room.id] {
                for window in windows {
                    let item = QuoteLineItem(
                        id: window.id,
                        roomName: room.name,
                        itemType: .window,
                        productName: window.productName,
                        variantName: window.variantName,
                        widthCm: window.widthCm,
                        heightOrLengthCm: window.heightCm,
                        pricePerSqm: window.pricePerSqm,
                        isIncluded: true
                    )
                    items.append(item)
                }
            }

            if let floors = floorsByRoom[room.id] {
                for floor in floors {
                    let item = QuoteLineItem(
                        id: floor.id,
                        roomName: room.name,
                        itemType: .floor,
                        productName: floor.productName,
                        variantName: floor.variantName,
                        widthCm: floor.widthCm,
                        heightOrLengthCm: floor.lengthCm,
                        pricePerSqm: floor.pricePerSqm,
                        isIncluded: true
                    )
                    items.append(item)
                }
            }
        }

        return items
    }

    func subtotal(from items: [QuoteLineItem]) -> Double {
        return items.filter { $0.isIncluded }.reduce(0) { $0 + $1.itemPrice }
    }

    func total(from items: [QuoteLineItem], discountPercent: Double) -> Double {
        let sub = subtotal(from: items)
        let discount = max(0, min(discountPercent, 100))
        return sub * (1.0 - discount / 100.0)
    }
}
