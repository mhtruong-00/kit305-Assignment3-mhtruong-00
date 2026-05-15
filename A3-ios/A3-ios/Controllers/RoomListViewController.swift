// With support from GitHub Copilot
import UIKit
import FirebaseFirestore

class RoomListViewController: UITableViewController {

    var house: House!

    private var rooms: [Room] = []
    private var filteredRooms: [Room] = []
    private var listener: ListenerRegistration?
    private let searchController = UISearchController(searchResultsController: nil)

    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No rooms yet.\nTap + to add a room."
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

    private var displayedRooms: [Room] {
        return isSearching ? filteredRooms : rooms
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = house.name
        navigationItem.largeTitleDisplayMode = .never
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
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addRoomTapped)),
            UIBarButtonItem(title: "Quote", style: .plain, target: self, action: #selector(quoteTapped))
        ]
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search rooms"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupTableView() {
        tableView.register(RoomCell.self, forCellReuseIdentifier: RoomCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.backgroundView = emptyLabel
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyLabel.widthAnchor.constraint(equalTo: tableView.widthAnchor, multiplier: 0.8)
        ])
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !displayedRooms.isEmpty
    }

    private func startListening() {
        listener?.remove()
        listener = FirestoreService.shared.listenToRooms(houseId: house.id) { [weak self] rooms in
            self?.rooms = rooms
            self?.tableView.reloadData()
            self?.updateEmptyState()
        }
    }

    @objc private func addRoomTapped() {
        let alert = UIAlertController(title: "Add Room", message: "Enter a name for the new room", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Room name"
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text,
                  !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            let room = Room(houseId: self.house.id, name: name.trimmingCharacters(in: .whitespaces))
            FirestoreService.shared.addRoom(room, houseId: self.house.id) { error in
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func quoteTapped() {
        let vc = QuoteViewController()
        vc.house = house
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedRooms.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RoomCell.reuseIdentifier, for: indexPath) as! RoomCell
        cell.configure(with: displayedRooms[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Rooms" : nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let room = displayedRooms[indexPath.row]
        let vc = RoomDetailViewController()
        vc.house = house
        vc.room = room
        navigationController?.pushViewController(vc, animated: true)
    }

    override func tableView(_ tableView: UITableView,
                             trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let room = displayedRooms[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Delete Room",
                                          message: "Delete \"\(room.name)\"?",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                FirestoreService.shared.deleteRoom(room.id, houseId: self.house.id) { error in
                    completion(error == nil)
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })
            self.present(alert, animated: true)
        }
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] _, _, completion in
            self?.renameRoom(room)
            completion(true)
        }
        renameAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
    }

    private func renameRoom(_ room: Room) {
        let alert = UIAlertController(title: "Rename Room", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = room.name
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text,
                  !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            var updated = room
            updated.name = name.trimmingCharacters(in: .whitespaces)
            FirestoreService.shared.updateRoom(updated, houseId: self.house.id) { error in
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension RoomListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""
        filteredRooms = rooms.filter { $0.name.lowercased().contains(query) }
        tableView.reloadData()
    }
}
