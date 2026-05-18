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

    // MARK: - Summary card (footer)

    private let summaryCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 14
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: -2)
        v.layer.shadowRadius = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        lbl.textColor = .secondaryLabel
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtotalCaption = QuoteViewController.makeCaption("Subtotal")
    private let subtotalValue   = QuoteViewController.makeValue()
    private let discountValue   = QuoteViewController.makeValue()
    private let totalCaption: UILabel = {
        let lbl = UILabel()
        lbl.text = "FINAL TOTAL"
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        lbl.textColor = .quoteTint
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    private let totalValue: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
        lbl.textColor = .quoteTint
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let totalDivider: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let discountField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "0"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .decimalPad
        tf.textAlignment = .center
        tf.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let percentLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "%"
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Quote — \(house.name)"
        navigationItem.backButtonTitle = ""
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareTapped))
        setupLayout()
        loadQuote()
        installNotesHeaderIfNeeded()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Layout

    private func setupLayout() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemGroupedBackground
        tableView.register(QuoteLineCell.self, forCellReuseIdentifier: QuoteLineCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 74

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        let discountLabel = UILabel()
        discountLabel.text = "Discount"
        discountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        discountLabel.textColor = .secondaryLabel
        discountLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(summaryCard)
        view.addSubview(activityIndicator)

        summaryCard.addSubview(statusLabel)
        summaryCard.addSubview(subtotalCaption)
        summaryCard.addSubview(subtotalValue)
        summaryCard.addSubview(discountLabel)
        summaryCard.addSubview(discountField)
        summaryCard.addSubview(percentLabel)
        summaryCard.addSubview(discountValue)
        summaryCard.addSubview(totalDivider)
        summaryCard.addSubview(totalCaption)
        summaryCard.addSubview(totalValue)

        NSLayoutConstraint.activate([
            summaryCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            summaryCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            summaryCard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            statusLabel.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 14),
            statusLabel.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -14),

            subtotalCaption.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            subtotalCaption.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 14),
            subtotalValue.centerYAnchor.constraint(equalTo: subtotalCaption.centerYAnchor),
            subtotalValue.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -14),

            discountLabel.topAnchor.constraint(equalTo: subtotalCaption.bottomAnchor, constant: 10),
            discountLabel.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 14),
            discountField.centerYAnchor.constraint(equalTo: discountLabel.centerYAnchor),
            discountField.leadingAnchor.constraint(equalTo: discountLabel.trailingAnchor, constant: 8),
            discountField.widthAnchor.constraint(equalToConstant: 60),
            discountField.heightAnchor.constraint(equalToConstant: 32),
            percentLabel.centerYAnchor.constraint(equalTo: discountField.centerYAnchor),
            percentLabel.leadingAnchor.constraint(equalTo: discountField.trailingAnchor, constant: 4),
            discountValue.centerYAnchor.constraint(equalTo: discountLabel.centerYAnchor),
            discountValue.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -14),

            totalDivider.topAnchor.constraint(equalTo: discountField.bottomAnchor, constant: 10),
            totalDivider.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 14),
            totalDivider.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -14),
            totalDivider.heightAnchor.constraint(equalToConstant: 1),

            totalCaption.topAnchor.constraint(equalTo: totalDivider.bottomAnchor, constant: 10),
            totalCaption.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 14),
            totalValue.centerYAnchor.constraint(equalTo: totalCaption.centerYAnchor),
            totalValue.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -14),
            totalValue.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -14),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: summaryCard.topAnchor, constant: -8),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])

        discountField.addTarget(self, action: #selector(applyDiscount), for: .editingChanged)
        discountField.addTarget(self, action: #selector(applyDiscount), for: .editingDidEndOnExit)
        discountField.addDoneInputAccessory(target: self, action: #selector(applyDiscount))
    }

    private static func makeCaption(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }
    private static func makeValue() -> UILabel {
        let lbl = UILabel()
        lbl.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    // MARK: - Loading

    private func installNotesHeaderIfNeeded() {
        let trimmed = house.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0))
        let card = UIView()
        card.backgroundColor = UIColor.quoteTint.withAlphaComponent(0.10)
        card.layer.cornerRadius = 10
        card.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "📝 Notes"
        title.font = .systemFont(ofSize: 12, weight: .heavy)
        title.textColor = .quoteTint
        title.translatesAutoresizingMaskIntoConstraints = false

        let body = UILabel()
        body.text = trimmed
        body.numberOfLines = 0
        body.font = .systemFont(ofSize: 14)
        body.textColor = .label
        body.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(card)
        card.addSubview(title)
        card.addSubview(body)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            card.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -12),
            card.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8),
            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            body.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            body.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            body.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
        // Size to fit
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let height = card.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width - 24,
                   height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height + 16
        header.frame.size.height = height
        tableView.tableHeaderView = header
    }

    private func loadQuote() {        activityIndicator.startAnimating()
        statusLabel.text = "Loading quote…"
        FirestoreService.shared.loadQuoteData(houseId: house.id) { [weak self] rooms, windows, floors in
            guard let self = self else { return }
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

        subtotalValue.text = String(format: "$%.2f", subtotal)
        discountValue.text = discountPercent > 0
            ? String(format: "−$%.2f", discount)
            : "$0.00"
        discountValue.textColor = discountPercent > 0 ? .systemOrange : .secondaryLabel
        totalValue.text = String(format: "$%.2f", total)

        var hints: [String] = []
        if usingDefaults {
            hints.append("Using default rates ($50 window · $100 floor) — product API unavailable.")
        }
        if roomQuotes.isEmpty {
            hints.append("No rooms in this house yet.")
        }
        let excluded = roomQuotes.filter { !$0.isIncluded }.count
        if excluded > 0 {
            hints.append("\(excluded) room\(excluded == 1 ? "" : "s") excluded.")
        }
        statusLabel.text = hints.joined(separator: "  ")
        statusLabel.isHidden = statusLabel.text?.isEmpty ?? true
    }

    // MARK: - Actions

    @objc private func applyDiscount() {
        let text = discountField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        discountPercent = max(0, min(100, Double(text) ?? 0))
        updateSummary()
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
        return roomQuotes[section].items.count + 1   // +1 for summary row
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let rq = roomQuotes[section]
        let header = UIView()
        header.backgroundColor = .systemGroupedBackground

        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 10
        card.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(card)

        let accent = UIView()
        accent.backgroundColor = .quoteTint
        accent.layer.cornerRadius = 2
        accent.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(accent)

        let titleLabel = UILabel()
        titleLabel.text = rq.room.name.isEmpty ? "Unnamed Room" : rq.room.name
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let countLabel = UILabel()
        let count = rq.items.count
        countLabel.text = "\(count) item\(count == 1 ? "" : "s")"
        countLabel.font = .systemFont(ofSize: 12)
        countLabel.textColor = .secondaryLabel
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        let toggle = UISwitch()
        toggle.onTintColor = .quoteTint
        toggle.isOn = rq.isIncluded
        toggle.tag = section
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(self, action: #selector(roomToggleChanged(_:)), for: .valueChanged)

        card.addSubview(titleLabel)
        card.addSubview(countLabel)
        card.addSubview(toggle)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            card.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -12),
            card.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -4),

            accent.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            accent.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            accent.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            accent.widthAnchor.constraint(equalToConstant: 4),

            titleLabel.leadingAnchor.constraint(equalTo: accent.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -8),

            countLabel.leadingAnchor.constraint(equalTo: accent.trailingAnchor, constant: 10),
            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            countLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),

            toggle.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            toggle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10)
        ])
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 60 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rq = roomQuotes[indexPath.section]

        if indexPath.row == rq.items.count {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.backgroundColor = .clear

            let labour = rq.labour(roomLabour: QuoteCalculator.roomLabour)
            let total = rq.roomTotal(roomLabour: QuoteCalculator.roomLabour)

            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = .tertiarySystemGroupedBackground
            container.layer.cornerRadius = 8
            cell.contentView.addSubview(container)

            let breakdown = UILabel()
            breakdown.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            breakdown.textColor = .secondaryLabel
            breakdown.translatesAutoresizingMaskIntoConstraints = false

            let totalLbl = UILabel()
            totalLbl.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .bold)
            totalLbl.textAlignment = .right
            totalLbl.translatesAutoresizingMaskIntoConstraints = false

            if rq.isIncluded {
                breakdown.text = String(format: "Items $%.2f  +  Labour $%.2f", rq.subtotal, labour)
                totalLbl.text = String(format: "$%.2f", total)
                totalLbl.textColor = .quoteTint
            } else {
                breakdown.text = "Room excluded from quote"
                totalLbl.text = "—"
                totalLbl.textColor = .tertiaryLabel
            }

            container.addSubview(breakdown)
            container.addSubview(totalLbl)
            NSLayoutConstraint.activate([
                container.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
                container.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
                container.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
                container.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),

                breakdown.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                breakdown.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                breakdown.trailingAnchor.constraint(lessThanOrEqualTo: totalLbl.leadingAnchor, constant: -8),
                totalLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
                totalLbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                container.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
            ])
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
