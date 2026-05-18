// With support from GitHub Copilot
import UIKit
import FirebaseFirestore

class HouseListViewController: UITableViewController {

    private var houses: [House] = []
    private var filteredHouses: [House] = []
    private var listener: ListenerRegistration?
    private let searchController = UISearchController(searchResultsController: nil)

    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No houses yet.\nTap + to add your first house."
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.textColor = .secondaryLabel
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }

    private var displayedHouses: [House] {
        return isSearching ? filteredHouses : houses
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Houses"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.backButtonTitle = ""
        setupNavigationBar()
        setupSearchController()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListening()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
        listener = nil
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addHouseTapped)),
            UIBarButtonItem(title: "Quote", style: .plain, target: self, action: #selector(quoteTapped))
        ]
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search houses"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupTableView() {
        tableView.register(HouseCell.self, forCellReuseIdentifier: HouseCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)

        tableView.backgroundView = emptyLabel
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyLabel.widthAnchor.constraint(equalTo: tableView.widthAnchor, multiplier: 0.8)
        ])
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !displayedHouses.isEmpty
    }

    private func startListening() {
        listener = FirestoreService.shared.listenToHouses { [weak self] houses in
            guard let self = self else { return }
            self.houses = houses
            UIView.transition(with: self.tableView,
                              duration: 0.2,
                              options: .transitionCrossDissolve,
                              animations: { self.tableView.reloadData() },
                              completion: nil)
            self.updateEmptyState()
            self.updateNavPrompt()
        }
    }

    private func updateNavPrompt() {
        // Mirrors the Android "Houses: N" header label.
        navigationItem.prompt = "Houses: \(houses.count)"
    }

    @objc private func addHouseTapped() {
        let vc = HouseEditViewController()
        vc.mode = .add
        vc.onSave = { [weak self] in self?.startListening() }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func quoteTapped() {
        guard !houses.isEmpty else {
            showAlert(title: "No Houses", message: "Add a house first before viewing quotes.")
            return
        }
        let alert = UIAlertController(title: "Select House", message: nil, preferredStyle: .actionSheet)
        for house in houses {
            alert.addAction(UIAlertAction(title: house.name, style: .default) { [weak self] _ in
                self?.openQuote(for: house)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        present(alert, animated: true)
    }

    private func openQuote(for house: House) {
        let vc = QuoteViewController()
        vc.house = house
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Table View Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedHouses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HouseCell.reuseIdentifier, for: indexPath) as! HouseCell
        cell.configure(with: displayedHouses[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let house = displayedHouses[indexPath.row]
        let vc = RoomListViewController()
        vc.house = house
        navigationController?.pushViewController(vc, animated: true)
    }

    override func tableView(_ tableView: UITableView,
                             trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let house = displayedHouses[indexPath.row]

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.confirmDelete(house: house, completion: completion)
        }
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            self?.editHouse(house)
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }

    private func confirmDelete(house: House, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Delete House",
                                      message: "Delete \"\(house.name)\"? This cannot be undone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            FirestoreService.shared.deleteHouse(house.id) { error in
                completion(error == nil)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })
        present(alert, animated: true)
    }

    private func editHouse(_ house: House) {
        let vc = HouseEditViewController()
        vc.mode = .edit(house)
        vc.onSave = { [weak self] in self?.startListening() }
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension HouseListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
        if query.isEmpty {
            filteredHouses = houses
        } else {
            filteredHouses = houses.filter {
                $0.name.lowercased().contains(query) || $0.address.lowercased().contains(query)
            }
        }
        tableView.reloadData()
        updateEmptyState()
    }
}
