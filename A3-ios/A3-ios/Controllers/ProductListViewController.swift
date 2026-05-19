// With support from GitHub Copilot
import UIKit

class ProductListViewController: UITableViewController {

    // Set before pushing to filter by category
    var category: String?  // "window" or "floor"
    // Space dimensions in mm (set by caller for window products)
    var spaceWidthMm: Int = 0
    var spaceHeightMm: Int = 0
    // Callback when a product + variant are selected (includes panelCount)
    var onProductSelected: ((_ product: Product, _ variant: ProductVariant?, _ panelCount: Int) -> Void)?

    private var allProducts: [Product] = []
    private var filteredProducts: [Product] = []
    private let searchController = UISearchController(searchResultsController: nil)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No products found."
        lbl.textAlignment = .center
        lbl.textColor = .secondaryLabel
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private var categoryTitle: String {
        switch category {
        case "window": return "Window Products"
        case "floor": return "Floor Products"
        default: return "Select Product"
        }
    }

    private var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    private var displayedProducts: [Product] {
        return isSearching ? filteredProducts : allProducts
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = categoryTitle
        navigationItem.backButtonTitle = ""
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
        navigationItem.hidesSearchBarWhenScrolling = false
        if #available(iOS 16.0, *) { navigationItem.preferredSearchBarPlacement = .stacked }
        definesPresentationContext = true
    }

    private func setupTableView() {
        tableView.register(ProductCell.self, forCellReuseIdentifier: ProductCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshProducts), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    @objc private func refreshProducts() {
        loadProducts()
        tableView.refreshControl?.endRefreshing()
    }

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        emptyLabel.isHidden = true
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !displayedProducts.isEmpty || activityIndicator.isAnimating
    }

    private func loadProducts() {
        activityIndicator.startAnimating()
        ProductAPI.shared.fetchProducts(category: category) { [weak self] products in
            self?.activityIndicator.stopAnimating()
            self?.allProducts = products
            self?.tableView.reloadData()
            self?.updateEmptyState()
        }
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedProducts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductCell.reuseIdentifier, for: indexPath) as! ProductCell
        let product = displayedProducts[indexPath.row]
        if product.category == "window" {
            let compat = CompatibilityChecker.check(product: product, widthMm: spaceWidthMm, heightMm: spaceHeightMm)
            cell.configure(with: product, compatibility: compat)
        } else {
            cell.configure(with: product)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let product = displayedProducts[indexPath.row]

        // Check compatibility for window products
        if product.category == "window" {
            let compat = CompatibilityChecker.check(product: product, widthMm: spaceWidthMm, heightMm: spaceHeightMm)
            if !compat.compatible {
                let alert = UIAlertController(
                    title: "Cannot Select",
                    message: compat.message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            let panelCount = compat.panelCount
            if product.variants.isEmpty {
                onProductSelected?(product, nil, panelCount)
                navigationController?.popToRootViewControllerThenPop()
            } else {
                let vc = ProductVariantViewController()
                vc.product = product
                vc.onVariantSelected = { [weak self] variant in
                    self?.onProductSelected?(product, variant, panelCount)
                    self?.navigationController?.popToRootViewControllerThenPop()
                }
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if product.variants.isEmpty {
                onProductSelected?(product, nil, 1)
                navigationController?.popToRootViewControllerThenPop()
            } else {
                let vc = ProductVariantViewController()
                vc.product = product
                vc.onVariantSelected = { [weak self] variant in
                    self?.onProductSelected?(product, variant, 1)
                    self?.navigationController?.popToRootViewControllerThenPop()
                }
                navigationController?.pushViewController(vc, animated: true)
            }
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
