// With support from GitHub Copilot
import Foundation

class ProductAPI {
    static let shared = ProductAPI()

    private let baseURL = "https://utasbot.dev/kit305_2026/product"

    private init() {}

    func fetchProducts(category: String? = nil, completion: @escaping ([Product]) -> Void) {
        var urlString = baseURL
        if let cat = category {
            urlString += "?category=\(cat)"
        }
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                let products = json.compactMap { Self.productFrom(dict: $0) }
                DispatchQueue.main.async { completion(products) }
            } catch {
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }

    private static func productFrom(dict: [String: Any]) -> Product? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String else { return nil }

        let description = dict["description"] as? String ?? ""
        let category = dict["category"] as? String ?? ""
        let imageUrl = dict["imageUrl"] as? String
        let pricePerSqm = dict["pricePerSqm"] as? Double ?? 0.0

        var variants: [ProductVariant] = []
        if let variantNames = dict["variants"] as? [String] {
            variants = variantNames.enumerated().map { idx, name in
                ProductVariant(id: "\(id)_v\(idx)", name: name)
            }
        }

        return Product(
            id: id,
            name: name,
            description: description,
            category: category,
            imageUrl: imageUrl,
            pricePerSqm: pricePerSqm,
            variants: variants
        )
    }
}
