// With support from GitHub Copilot
// Quote calculation that matches the Android QuoteActivity behaviour:
//   * Per-room subtotal
//   * Per-room labour fee ($200) when the room has at least one MEASURED + INCLUDED item
//   * Default rates ($50 window, $100 floor) when no product rate is known
//   * Whole-house discount %
import Foundation

/// Per-room quote totals as computed by `QuoteCalculator`.
struct RoomQuote {
    let room: Room
    var items: [QuoteLineItem]
    var isIncluded: Bool

    var subtotal: Double {
        return items.filter { $0.isIncluded }.reduce(0) { $0 + $1.itemPrice }
    }
    var hasMeasuredIncludedItem: Bool {
        return items.contains { $0.isIncluded && $0.areaSqm > 0 }
    }
    /// Labour only applies if the room is included AND has a measured+included item.
    func labour(roomLabour: Double) -> Double {
        return (isIncluded && hasMeasuredIncludedItem) ? roomLabour : 0
    }
    func roomTotal(roomLabour: Double) -> Double {
        return isIncluded ? subtotal + labour(roomLabour: roomLabour) : 0
    }
}

class QuoteCalculator {
    static let shared = QuoteCalculator()
    private init() {}

    /// Pricing defaults — match the Android `QuoteActivity` constants.
    static let defaultWindowRate: Double = 50.0
    static let defaultFloorRate: Double  = 100.0
    static let roomLabour: Double        = 200.0

    /// Build `RoomQuote` objects ready for the quote screen.
    /// - Parameters:
    ///   - productRates: map of `productId -> pricePerSqm` (typically loaded from the
    ///     product API at quote time).
    func buildRoomQuotes(rooms: [Room],
                         windowsByRoom: [String: [WindowItem]],
                         floorsByRoom: [String: [FloorSpace]],
                         productRates: [String: Double]) -> [RoomQuote] {
        return rooms.map { room in
            var items: [QuoteLineItem] = []

            for w in windowsByRoom[room.id] ?? [] {
                let (rate, isDefault) = resolveRate(productId: w.selectedProductId,
                                                    rates: productRates,
                                                    defaultRate: Self.defaultWindowRate)
                items.append(QuoteLineItem(
                    id: w.id,
                    roomId: room.id,
                    roomName: room.name,
                    itemType: .window,
                    itemName: w.name,
                    productId: w.selectedProductId,
                    productName: w.selectedProductName.isEmpty ? "Basic Window" : w.selectedProductName,
                    variantName: w.selectedProductVariant,
                    widthMm: w.widthMm,
                    heightOrDepthMm: w.heightMm,
                    panelCount: w.panelCount,
                    pricePerSqm: rate,
                    isIncluded: true,
                    usedDefaultRate: isDefault
                ))
            }
            for f in floorsByRoom[room.id] ?? [] {
                let (rate, isDefault) = resolveRate(productId: f.selectedProductId,
                                                    rates: productRates,
                                                    defaultRate: Self.defaultFloorRate)
                items.append(QuoteLineItem(
                    id: f.id,
                    roomId: room.id,
                    roomName: room.name,
                    itemType: .floor,
                    itemName: f.name,
                    productId: f.selectedProductId,
                    productName: f.selectedProductName.isEmpty ? "Basic Floor" : f.selectedProductName,
                    variantName: f.selectedProductVariant,
                    widthMm: f.widthMm,
                    heightOrDepthMm: f.depthMm,
                    panelCount: 1,
                    pricePerSqm: rate,
                    isIncluded: true,
                    usedDefaultRate: isDefault
                ))
            }

            return RoomQuote(room: room, items: items, isIncluded: true)
        }
    }

    /// Sum of (room subtotals + room labour) for all included rooms.
    func houseSubtotal(from roomQuotes: [RoomQuote]) -> Double {
        return roomQuotes.reduce(0) { $0 + $1.roomTotal(roomLabour: Self.roomLabour) }
    }

    /// Apply the % discount to the house subtotal.
    func finalTotal(from roomQuotes: [RoomQuote], discountPercent: Double) -> Double {
        let sub = houseSubtotal(from: roomQuotes)
        let d = max(0, min(100, discountPercent))
        return sub * (1.0 - d / 100.0)
    }

    func discountAmount(from roomQuotes: [RoomQuote], discountPercent: Double) -> Double {
        let sub = houseSubtotal(from: roomQuotes)
        let d = max(0, min(100, discountPercent))
        return sub * (d / 100.0)
    }

    private func resolveRate(productId: String,
                             rates: [String: Double],
                             defaultRate: Double) -> (Double, Bool) {
        if productId.isEmpty { return (defaultRate, true) }
        if let rate = rates[productId] { return (rate, false) }
        return (defaultRate, true)
    }
}
