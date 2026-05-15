// With support from GitHub Copilot
import UIKit
import FirebaseFirestore

class RoomDetailViewController: UIViewController {

    var house: House!
    var room: Room!

    private var windows: [WindowItem] = []
    private var floors: [FloorSpace] = []
    private var windowListener: ListenerRegistration?
    private var floorListener: ListenerRegistration?

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let roomNameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = room.name
        navigationItem.backButtonTitle = ""
        setupNavigationBar()
        setupTableView()
        startListening()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        windowListener?.remove()
        floorListener?.remove()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Rename",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(renameTapped))
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(WindowCell.self, forCellReuseIdentifier: WindowCell.reuseIdentifier)
        tableView.register(FloorSpaceCell.self, forCellReuseIdentifier: FloorSpaceCell.reuseIdentifier)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func startListening() {
        windowListener = FirestoreService.shared.listenToWindows(houseId: house.id, roomId: room.id) { [weak self] items in
            self?.windows = items
            self?.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
        floorListener = FirestoreService.shared.listenToFloorSpaces(houseId: house.id, roomId: room.id) { [weak self] items in
            self?.floors = items
            self?.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
    }

    @objc private func renameTapped() {
        let alert = UIAlertController(title: "Rename Room", message: nil, preferredStyle: .alert)
        alert.addTextField { [weak self] tf in
            tf.text = self?.room.name
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text,
                  !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            self.room.name = name.trimmingCharacters(in: .whitespaces)
            self.title = self.room.name
            FirestoreService.shared.updateRoom(self.room, houseId: self.house.id) { _ in }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func addWindowTapped() {
        let vc = WindowEditViewController()
        vc.house = house
        vc.room = room
        vc.mode = .add
        navigationController?.pushViewController(vc, animated: true)
    }

    private func addFloorTapped() {
        let vc = FloorSpaceEditViewController()
        vc.house = house
        vc.room = room
        vc.mode = .add
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension RoomDetailViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { return 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? windows.count : floors.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Windows" : "Floor Spaces"
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(section == 0 ? "+ Add Window" : "+ Add Floor Space", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        btn.tag = section
        btn.addTarget(self, action: #selector(addItemTapped(_:)), for: .touchUpInside)
        footer.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.centerXAnchor.constraint(equalTo: footer.centerXAnchor),
            btn.topAnchor.constraint(equalTo: footer.topAnchor, constant: 8),
            btn.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: -8)
        ])
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { return 44 }

    @objc private func addItemTapped(_ sender: UIButton) {
        if sender.tag == 0 {
            addWindowTapped()
        } else {
            addFloorTapped()
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: WindowCell.reuseIdentifier, for: indexPath) as! WindowCell
            cell.configure(with: windows[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: FloorSpaceCell.reuseIdentifier, for: indexPath) as! FloorSpaceCell
            cell.configure(with: floors[indexPath.row])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let vc = WindowEditViewController()
            vc.house = house
            vc.room = room
            vc.mode = .edit(windows[indexPath.row])
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = FloorSpaceEditViewController()
            vc.house = house
            vc.room = room
            vc.mode = .edit(floors[indexPath.row])
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return completion(false) }
            if indexPath.section == 0 {
                let window = self.windows[indexPath.row]
                let alert = UIAlertController(title: "Delete Window", message: "Delete this window?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    FirestoreService.shared.deleteWindow(window.id, houseId: self.house.id, roomId: self.room.id) { error in
                        completion(error == nil)
                    }
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })
                self.present(alert, animated: true)
            } else {
                let floor = self.floors[indexPath.row]
                let alert = UIAlertController(title: "Delete Floor Space", message: "Delete this floor space?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    FirestoreService.shared.deleteFloorSpace(floor.id, houseId: self.house.id, roomId: self.room.id) { error in
                        completion(error == nil)
                    }
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })
                self.present(alert, animated: true)
            }
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
