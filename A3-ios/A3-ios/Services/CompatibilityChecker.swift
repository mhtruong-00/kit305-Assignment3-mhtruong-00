// With support from GitHub Copilot
import Foundation

struct CompatibilityResult {
    let compatible: Bool
    let panelCount: Int
    let message: String
}

enum CompatibilityChecker {

    /// Check whether a product is compatible with a given window/floor space.
    /// - Parameters:
    ///   - product: The product to check.
    ///   - widthMm: Width of the space in millimetres (pass 0 if not set).
    ///   - heightMm: Height of the space in millimetres (pass 0 if not set).
    /// - Returns: A `CompatibilityResult` describing compatibility, panel count, and a human-readable message.
    static func check(product: Product, widthMm: Int, heightMm: Int) -> CompatibilityResult {
        // Floor products are always compatible
        guard product.category == "window" else {
            return CompatibilityResult(compatible: true, panelCount: 1, message: "")
        }

        // No dimensions set
        if widthMm <= 0 && heightMm <= 0 {
            return CompatibilityResult(compatible: true, panelCount: 1, message: "No dimensions set")
        }

        // Height check
        if heightMm > 0 {
            if heightMm < product.minHeight {
                return CompatibilityResult(
                    compatible: false,
                    panelCount: 1,
                    message: "Too short: \(heightMm)mm (min \(product.minHeight)mm required)"
                )
            }
            if heightMm > product.maxHeight {
                return CompatibilityResult(
                    compatible: false,
                    panelCount: 1,
                    message: "Too tall: \(heightMm)mm (max \(product.maxHeight)mm allowed)"
                )
            }
        }

        // Width check
        if widthMm > 0 {
            let maxPanels = max(1, product.maxPanelCount)
            for panels in 1...maxPanels {
                let panelWidth = widthMm / panels
                if panelWidth >= product.minWidth && panelWidth <= product.maxWidth {
                    let message: String
                    if panels == 1 {
                        message = "Single panel — \(widthMm)mm wide"
                    } else {
                        message = "\(panels) panels — each ~\(panelWidth)mm wide"
                    }
                    return CompatibilityResult(compatible: true, panelCount: panels, message: message)
                }
            }
            // No panel count fits
            let failMessage: String
            if widthMm < product.minWidth {
                failMessage = "Too narrow: \(widthMm)mm (min \(product.minWidth)mm per panel)"
            } else if product.maxPanelCount <= 1 {
                failMessage = "Too wide: \(widthMm)mm exceeds \(product.maxWidth)mm (single panel only)"
            } else {
                failMessage = "Cannot fit: \(widthMm)mm cannot be split into 1–\(product.maxPanelCount) panels each \(product.minWidth)–\(product.maxWidth)mm wide"
            }
            return CompatibilityResult(compatible: false, panelCount: 1, message: failMessage)
        }

        // Height passed but no width
        return CompatibilityResult(compatible: true, panelCount: 1, message: "No width set")
    }
}
