// With support from GitHub Copilot
// Quote screen aligned with Android `QuoteActivity`:
//  * Loads rooms + windows + floors for the selected house.
//  * Fetches product rates from the API; falls back to defaults if unavailable.
//  * Per-room subtotal + $200 labour for measured rooms.
//  * Whole-house discount %.
//  * Per-room and per-item include toggles.
//  * Shares the resulting CSV.
import UIKit

class QuoteViewController: UIViewController {

    var house: House!

    private var roomQuotes: [RoomQuote] = []
    private var usingDefaults: Bool = false
    private var discountPercent: Double = 0

    private let tableView = UITableView(frame: .zero, style: .grouped)

    private let summaryView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGroupedBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.textColor = .secondaryLabel
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtotalLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let discountField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "%"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .decimalPad
        tf.textAlignment = .center
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let discountLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Discount (%):"
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let applyDiscountButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Apply", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let clearDiscountButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Clear", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let totalLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Quote — \(house.name)"
        navigationItem.backButtonTitle = ""
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareTapped))
        setupLayout()
        loadQuote()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Layout

    private func setupLayout() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(QuoteLineCell.self, forCellReuseIdentifier: QuoteLineCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        let discountRow = UIStackView(arrangedSubviews: [discountLabel, discountField, applyDiscountButton, clearDiscountButton])
        discountRow.axis = .horizontal
        discountRow.spacing = 8
        discountRow.translatesAutoresizingMaskIntoConstraints = false
        discountField.widthAnchor.constraint(equalToConstant: 70).isActive = true

        view.addSubview(tableView)
        view.addSubview(summaryView)
        view.addSubview(activityIndicator)

        summaryView.addSubview(statusLabel)
        summaryView.addSubview(subtotalLabel)
        summaryView.addSubview(discountRow)
        summaryView.addSubview(totalLabel)

        NSLayoutConstraint.activate([
            summaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            summaryView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            summaryView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            statusLabel.topAnchor.constraint(equalTo: summaryView.topAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor, constant: -16),

            subtotalLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            subtotalLabel.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor, constant: 16),
            subtotalLabel.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor, constant: -16),

            discountRow.topAnchor.constraint(equalTo: subtotalLabel.bottomAnchor, constant: 8),
            discountRow.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor, constant: 16),
            discountRow.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor, constant: -16),

            totalLabel.topAnchor.constraint(equalTo: discountRow.bottomAnchor, constant: 8),
            totalLabel.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor, constant: 16),
            totalLabel.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor, constant: -16),
            totalLabel.bottomAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: -12),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: summaryView.topAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])

        applyDiscountButton.addTarget(self, action: #selector(applyDiscount), for: .touchUpInside)
        clearDiscountButton.addTarget(self, action: #selector(clearDiscount), for: .touchUpInside)
        discountField.addTarget(self, action: #selector(applyDiscount), for: .editingDidEndOnExit)
        discountField.addDoneInputAccessory(target: self, action: #selector(applyDiscount))
    }

    // MARK: - Loading

    private func loadQuote() {
        activityIndicator.startAnimating()
        statusLabel.text = "Loading quote…"
        FirestoreService.shared.loadQuoteData(houseId: house.id) { [weak self] rooms, windows, floors in
            guard let self = self else { return }
            // Now fetch all products so we can resolve rates.
            ProductAPI.shared.fetchProducts(category: nil) { products in
                self.activityIndicator.stopAnimating()
                let rates = Dictionary(uniqueKeysWithValues:
                    products.compactMap { p -> (String, Double)? in
                        p.id.isEmpty ? nil : (p.id, p.pricePerSqm)
                    })
                self.usingDefaults = products.isEmpty
                self.roomQuotes = QuoteCalculator.shared.buildRoomQuotes(
                    rooms: rooms,
                    windowsByRoom: windows,
                    floorsByRoom: floors,
                    productRates: rates)
                self.tableView.reloadData()
                self.updateSummary()
            }
        }
    }

    private func updateSummary() {
        let subtotal = QuoteCalculator.shared.houseSubtotal(from: roomQuotes)
        let discount = QuoteCalculator.shared.discountAmount(from: roomQuotes, discountPercent: discountPercent)
        let total    = QuoteCalculator.shared.finalTotal(from: roomQuotes, discountPercent: discountPercent)
        let includedItems = roomQuotes.flatMap { rq in
            rq.isIncluded ? rq.items.filter { $0.isIncluded } : []
        }.count
        subtotalLabel.text = String(format: "Subtotal (%d items): $%.2f", includedItems, subtotal)
        if discountPercent > 0 {
            totalLabel.text = String(format: "Total: $%.2f  (–$%.2f at %.1f%%)", total, discount, discountPercent)
            totalLabel.textColor = .systemGreen
        } else {
            totalLabel.text = String(format: "Total: $%.2f", total)
            totalLabel.textColor = .label
        }
        if usingDefaults {
            statusLabel.text = "Using default rates ($50/sqm window, $100/sqm floor) — product API unavailable."
        } else {
            statusLabel.text = roomQuotes.isEmpty ? "No rooms in this house yet." : ""
        }
    }

    // MARK: - Actions

    @objc private func applyDiscount() {
        let text = discountField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        discountPercent = max(0, min(100, Double(text) ?? 0))
        updateSummary()
        view.endEditing(true)
    }

    @objc private func clearDiscount() {
        discountPercent = 0
        discountField.text = ""
        updateSummary()
        view.endEditing(true)
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func shareTapped() {
        applyDiscount()
        let csv = CSVExporter.shared.generateCSV(
            houseName: house.name,
            address: house.address,
            roomQuotes: roomQuotes,
            discountPercent: discountPercent,
            usingDefaults: usingDefaults)
        let date = DateFormatter.timestampFormatter.string(from: Date())
        let safeName = house.name.replacingOccurrences(of: " ", with: "_").nonEmpty ?? "quote"
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("quote_\(safeName)_\(date).csv")
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            let vc = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let popover = vc.popoverPresentationController {
                popover.barButtonItem = navigationItem.rightBarButtonItem
            }
            present(vc, animated: true)
        } catch {
            let vc = UIActivityViewController(activityItems: [csv], applicationActivities: nil)
            present(vc, animated: true)
        }
    }
}

// MARK: - Table View

extension QuoteViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return roomQuotes.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // +1 for the room subtotal/labour summary row at the end.
        return roomQuotes[section].items.count + 1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let rq = roomQuotes[section]
        let header = UIView()
        header.backgroundColor = .secondarySystemBackground

        let titleLabel = UILabel()
        titleLabel.text = rq.room.name.isEmpty ? "Unnamed Room" : rq.room.name
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let toggle = UISwitch()
        toggle.isOn = rq.isIncluded
        toggle.tag = section
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(self, action: #selector(roomToggleChanged(_:)), for: .valueChanged)

        header.addSubview(titleLabel)
        header.addSubview(toggle)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            toggle.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            toggle.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            header.heightAnchor.constraint(equalToConstant: 44)
        ])
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 44 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rq = roomQuotes[indexPath.section]

        // Last row is the room summary.
        if indexPath.row == rq.items.count {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.selectionStyle = .none
            let labour = rq.labour(roomLabour: QuoteCalculator.roomLabour)
            let total = rq.roomTotal(roomLabour: QuoteCalculator.roomLabour)
            if rq.isIncluded {
                cell.textLabel?.text = String(format: "Subtotal: $%.2f  + Labour: $%.2f", rq.subtotal, labour)
                cell.detailTextLabel?.text = String(format: "Room total: $%.2f", total)
            } else {
                cell.textLabel?.text = "Room excluded"
                cell.detailTextLabel?.text = "—"
            }
            cell.textLabel?.font = .systemFont(ofSize: 13)
            cell.textLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.font = .monospacedSystemFont(ofSize: 14, weight: .semibold)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: QuoteLineCell.reuseIdentifier, for: indexPath) as! QuoteLineCell
        let item = rq.items[indexPath.row]
        cell.configure(with: item)
        cell.contentView.alpha = rq.isIncluded ? (item.isIncluded ? 1.0 : 0.5) : 0.4
        cell.includeSwitch.isEnabled = rq.isIncluded
        cell.switchToggleHandler = { [weak self] isOn in
            guard let self = self else { return }
            self.roomQuotes[indexPath.section].items[indexPath.row].isIncluded = isOn
            self.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
            self.updateSummary()
        }
        return cell
    }

    @objc private func roomToggleChanged(_ sender: UISwitch) {
        let section = sender.tag
        guard section >= 0 && section < roomQuotes.count else { return }
        roomQuotes[section].isIncluded = sender.isOn
        tableView.reloadSections(IndexSet(integer: section), with: .none)
        updateSummary()
    }
}
