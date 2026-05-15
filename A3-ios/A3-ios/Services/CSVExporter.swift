// With support from GitHub Copilot
import Foundation

class CSVExporter {
    static let shared = CSVExporter()
    private init() {}

    func generateCSV(houseName: String, address: String,
                     items: [QuoteLineItem], discountPercent: Double) -> String {
        var lines: [String] = []

        lines.append("Interior Design Quote")
        lines.append("House: \(escapeCSV(houseName))")
        lines.append("Address: \(escapeCSV(address))")
        lines.append("")
        lines.append("Room,Type,Product,Variant,Width (cm),Height/Length (cm),Area (sqm),Price/sqm,Item Price,Included")

        for item in items {
            let includedStr = item.isIncluded ? "Yes" : "No"
            let line = [
                escapeCSV(item.roomName),
                escapeCSV(item.typeLabel),
                escapeCSV(item.productName),
                escapeCSV(item.variantName),
                String(format: "%.1f", item.widthCm),
                String(format: "%.1f", item.heightOrLengthCm),
                String(format: "%.4f", item.areaSqm),
                String(format: "%.2f", item.pricePerSqm),
                String(format: "%.2f", item.itemPrice),
                includedStr
            ].joined(separator: ",")
            lines.append(line)
        }

        lines.append("")
        let subtotal = QuoteCalculator.shared.subtotal(from: items)
        let total = QuoteCalculator.shared.total(from: items, discountPercent: discountPercent)
        lines.append("Subtotal,\(String(format: "%.2f", subtotal))")
        if discountPercent > 0 {
            lines.append("Discount,\(String(format: "%.1f", discountPercent))%")
        }
        lines.append("Total,\(String(format: "%.2f", total))")

        return lines.joined(separator: "\n")
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
