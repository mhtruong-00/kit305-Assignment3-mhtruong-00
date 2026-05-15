// With support from GitHub Copilot
import UIKit

class ProductVariantViewController: UITableViewController {

    var product: Product!
    var onVariantSelected: ((ProductVariant) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = product.name
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "VariantCell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return product.variants.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VariantCell", for: indexPath)
        let variant = product.variants[indexPath.row]
        cell.textLabel?.text = variant.name
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Select a Variant"
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let variant = product.variants[indexPath.row]
        onVariantSelected?(variant)
    }
}
