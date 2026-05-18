// With support from GitHub Copilot
// CSV output mirroring the Android share format.
import Foundation

class CSVExporter {
    static let shared = CSVExporter()
    private init() {}

    /// Build the CSV string shared from the quote screen.
    func generateCSV(houseName: String,
                     address: String,
                     roomQuotes: [RoomQuote],
                     discountPercent: Double,
                     usingDefaults: Bool) -> String {

        var rows: [String] = []
        rows.append(csvRow([
            "type", "house", "address", "room",
            "item_type", "item_name",
            "width_mm", "height_or_depth_mm",
            "product", "variant",
            "rate_per_sqm", "area_sqm", "item_cost",
            "room_subtotal", "room_labour", "room_total", "included"
        ]))

        for rq in roomQuotes {
            for item in rq.items {
                let includeItem = rq.isIncluded && item.isIncluded
                let cost = includeItem ? item.itemPrice : 0
                rows.append(csvRow([
                    "item",
                    houseName, address,
                    rq.room.name.isEmpty ? "Unnamed Room" : rq.room.name,
                    item.itemType == .window ? "window" : "floor",
                    item.itemName.isEmpty ? "Unnamed" : item.itemName,
                    "\(item.widthMm)", "\(item.heightOrDepthMm)",
                    item.productName, item.variantName,
                    money(item.pricePerSqm), area(item.areaSqm), money(cost),
                    "", "", "",
                    includeItem ? "true" : "false"
                ]))
            }
            let labour = rq.labour(roomLabour: QuoteCalculator.roomLabour)
            let total  = rq.roomTotal(roomLabour: QuoteCalculator.roomLabour)
            rows.append(csvRow([
                "room_total",
                houseName, address,
                rq.room.name.isEmpty ? "Unnamed Room" : rq.room.name,
                "", "", "", "", "", "", "", "",
                money(rq.subtotal), money(labour), money(total),
                rq.isIncluded ? "true" : "false"
            ]))
        }

        let houseSubtotal = QuoteCalculator.shared.houseSubtotal(from: roomQuotes)
        let discountAmt   = QuoteCalculator.shared.discountAmount(from: roomQuotes, discountPercent: discountPercent)
        let finalTotal    = QuoteCalculator.shared.finalTotal(from: roomQuotes, discountPercent: discountPercent)

        rows.append(csvRow(["summary", houseName, address] + Array(repeating: "", count: 14)))
        rows.append(csvRow(["subtotal", houseName, address, "", "", "", "", "", "", "", "", "", money(houseSubtotal), "", "", "", ""]))
        rows.append(csvRow(["discount", houseName, address, "", "", "", "", "", "", "", "", "", money(discountAmt), "", "", "", percent(discountPercent)]))
        rows.append(csvRow(["final_total", houseName, address, "", "", "", "", "", "", "", "", "", money(finalTotal), "", "", "", ""]))

        if usingDefaults {
            rows.append(csvRow(["note", houseName, address, "", "", "", "", "", "Using default product rates", "", "", "", "", "", "", "", ""]))
        }

        return rows.joined(separator: "\n")
    }

    // MARK: helpers

    private func csvRow(_ values: [String]) -> String {
        return values.map(escape).joined(separator: ",")
    }

    private func escape(_ v: String) -> String {
        let escaped = v.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private func money(_ v: Double) -> String  { String(format: "%.2f", v) }
    private func area(_ v: Double) -> String   { String(format: "%.2f", v) }
    private func percent(_ v: Double) -> String { String(format: "%.1f", v) }
}
