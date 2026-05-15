// With support from GitHub Copilot
import UIKit

class ProductListViewController: UITableViewController {

    // Set before pushing to filter by category
    var category: String?  // "window" or "floor"
    // Callback when a product + variant are selected
    var onProductSelected: ((_ product: Product, _ variant: ProductVariant?) -> Void)?

    private var allProducts: [Product] = []
    private var filteredProducts: [Product] = []
    private let searchController = UISearchController(searchResultsController: nil)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    private var displayedProducts: [Product] {
        return isSearching ? filteredProducts : allProducts
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Product"
        setupSearch()
        setupTableView()
        setupActivityIndicator()
        loadProducts()
    }

    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search products"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupTableView() {
        tableView.register(ProductCell.self, forCellReuseIdentifier: ProductCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadProducts() {
        activityIndicator.startAnimating()
        ProductAPI.shared.fetchProducts(category: category) { [weak self] products in
            self?.activityIndicator.stopAnimating()
            self?.allProducts = products
            self?.tableView.reloadData()
        }
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedProducts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductCell.reuseIdentifier, for: indexPath) as! ProductCell
        cell.configure(with: displayedProducts[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let product = displayedProducts[indexPath.row]
        if product.variants.isEmpty {
            onProductSelected?(product, nil)
            navigationController?.popToRootViewControllerThenPop()
        } else {
            let vc = ProductVariantViewController()
            vc.product = product
            vc.onVariantSelected = { [weak self] variant in
                self?.onProductSelected?(product, variant)
                self?.navigationController?.popToRootViewControllerThenPop()
            }
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension ProductListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""
        filteredProducts = allProducts.filter {
            $0.name.lowercased().contains(query) || $0.description.lowercased().contains(query)
        }
        tableView.reloadData()
    }
}

private extension UINavigationController {
    func popToRootViewControllerThenPop() {
        // Pop back 2 levels (ProductVariant -> ProductList -> WindowEdit/FloorEdit)
        // Actually just pop back to the edit VC
        if viewControllers.count >= 2 {
            let target = viewControllers[viewControllers.count - 2]
            if target is ProductListViewController {
                if viewControllers.count >= 3 {
                    popToViewController(viewControllers[viewControllers.count - 3], animated: true)
                } else {
                    popToRootViewController(animated: true)
                }
            } else {
                popViewController(animated: true)
            }
        }
    }
}
