// With support from GitHub Copilot
import Foundation

class ProductAPI {
    static let shared = ProductAPI()

    private let baseURL = "https://utasbot.dev/kit305_2026/product"

    private init() {}

    func fetchProducts(category: String? = nil, completion: @escaping ([Product]) -> Void) {
        guard var components = URLComponents(string: baseURL) else {
            DispatchQueue.main.async { completion([]) }
            return
        }
        if let cat = category, !cat.isEmpty {
            components.queryItems = [URLQueryItem(name: "category", value: cat)]
        }
        guard let url = components.url else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[ProductAPI] network error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion([]) }
                return
            }
            guard let data = data else {
                print("[ProductAPI] no data returned")
                DispatchQueue.main.async { completion([]) }
                return
            }
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                print("[ProductAPI] HTTP \(http.statusCode)")
                DispatchQueue.main.async { completion([]) }
                return
            }

            let products = Self.parseProducts(data: data)
            print("[ProductAPI] parsed \(products.count) products for category=\(category ?? "all")")
            DispatchQueue.main.async { completion(products) }
        }.resume()
    }

    /// Parse the API response. Supports both:
    ///   1. A bare JSON array:        `[ {...}, {...} ]`
    ///   2. A wrapped object payload: `{ "data": [ {...}, {...} ] }`
    private static func parseProducts(data: Data) -> [Product] {
        let raw = (try? JSONSerialization.jsonObject(with: data)) as Any?
        let array: [[String: Any]]
        if let arr = raw as? [[String: Any]] {
            array = arr
        } else if let obj = raw as? [String: Any], let arr = obj["data"] as? [[String: Any]] {
            array = arr
        } else {
            print("[ProductAPI] unexpected JSON shape")
            return []
        }
        return array.compactMap { productFrom(dict: $0) }
    }

    private static func productFrom(dict: [String: Any]) -> Product? {
        // id can come back as string or int; coerce to string
        let id: String
        if let s = dict["id"] as? String { id = s }
        else if let i = dict["id"] as? Int { id = String(i) }
        else { return nil }

        guard let name = dict["name"] as? String, !name.isEmpty else { return nil }

        let description = dict["description"] as? String ?? ""
        let category = dict["category"] as? String ?? ""
        let imageUrl = (dict["image_url"] as? String) ?? (dict["imageUrl"] as? String)

        // price_per_sqm may come back as Double, Int, or NSNumber
        let pricePerSqm: Double
        if let d = dict["price_per_sqm"] as? Double { pricePerSqm = d }
        else if let i = dict["price_per_sqm"] as? Int { pricePerSqm = Double(i) }
        else if let n = dict["price_per_sqm"] as? NSNumber { pricePerSqm = n.doubleValue }
        else if let d = dict["pricePerSqm"] as? Double { pricePerSqm = d }
        else if let i = dict["pricePerSqm"] as? Int { pricePerSqm = Double(i) }
        else { pricePerSqm = 0.0 }

        var variants: [ProductVariant] = []
        if let variantNames = dict["variants"] as? [String] {
            variants = variantNames.enumerated().map { idx, name in
                ProductVariant(id: "\(id)_v\(idx)", name: name)
            }
        } else if let variantObjs = dict["variants"] as? [[String: Any]] {
            variants = variantObjs.enumerated().compactMap { idx, v in
                let vname = (v["name"] as? String) ?? (v["variant"] as? String) ?? ""
                guard !vname.isEmpty else { return nil }
                let vid = (v["id"] as? String) ?? "\(id)_v\(idx)"
                return ProductVariant(id: vid, name: vname)
            }
        }

        let minWidth = intCoerce(dict["min_width"] ?? dict["minWidth"]) ?? 0
        let maxWidth = intCoerce(dict["max_width"] ?? dict["maxWidth"]) ?? 9999
        let minHeight = intCoerce(dict["min_height"] ?? dict["minHeight"]) ?? 0
        let maxHeight = intCoerce(dict["max_height"] ?? dict["maxHeight"]) ?? 9999
        // max_panels is the API key; maxPanels and maxPanelCount are accepted for forward-compatibility
        let maxPanelCount = intCoerce(dict["max_panels"] ?? dict["maxPanels"] ?? dict["maxPanelCount"]) ?? 1

        return Product(
            id: id,
            name: name,
            description: description,
            category: category,
            imageUrl: imageUrl,
            pricePerSqm: pricePerSqm,
            variants: variants,
            minWidth: minWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            maxHeight: maxHeight,
            maxPanelCount: maxPanelCount
        )
    }

    /// Tolerantly coerce Any? (String / Int / Double) to Int
    private static func intCoerce(_ value: Any?) -> Int? {
        guard let value = value else { return nil }
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let n = value as? NSNumber { return n.intValue }
        if let s = value as? String, let i = Int(s) { return i }
        return nil
    }
}
