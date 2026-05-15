// With support from GitHub Copilot
import UIKit

class QuoteViewController: UIViewController {

    var house: House!

    private var lineItems: [QuoteLineItem] = []
    private var discountPercent: Double = 0

    private let tableView = UITableView(frame: .zero, style: .plain)

    private let summaryView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGroupedBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let subtotalLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let discountField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Discount %"
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

    private let totalLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let applyDiscountButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Apply", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Quote — \(house.name)"
        navigationItem.backButtonTitle = ""
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped)),
            UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(toggleSelectAll))
        ]
        setupLayout()
        loadQuoteData()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupLayout() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(QuoteLineCell.self, forCellReuseIdentifier: QuoteLineCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        let discountRow = UIStackView(arrangedSubviews: [discountLabel, discountField, applyDiscountButton])
        discountRow.axis = .horizontal
        discountRow.spacing = 8
        discountRow.translatesAutoresizingMaskIntoConstraints = false
        discountField.widthAnchor.constraint(equalToConstant: 70).isActive = true

        view.addSubview(tableView)
        view.addSubview(summaryView)
        view.addSubview(activityIndicator)

        summaryView.addSubview(subtotalLabel)
        summaryView.addSubview(discountRow)
        summaryView.addSubview(totalLabel)

        NSLayoutConstraint.activate([
            summaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            summaryView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            summaryView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            subtotalLabel.topAnchor.constraint(equalTo: summaryView.topAnchor, constant: 12),
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
        discountField.addTarget(self, action: #selector(applyDiscount), for: .editingDidEndOnExit)
        discountField.addDoneInputAccessory(target: self, action: #selector(applyDiscount))
    }

    private func loadQuoteData() {
        activityIndicator.startAnimating()
        FirestoreService.shared.loadQuoteData(houseId: house.id) { [weak self] rooms, windows, floors in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.lineItems = QuoteCalculator.shared.buildLineItems(
                rooms: rooms, windowsByRoom: windows, floorsByRoom: floors)
            self.tableView.reloadData()
            self.updateSummary()
        }
    }

    private func updateSummary() {
        let subtotal = QuoteCalculator.shared.subtotal(from: lineItems)
        let total = QuoteCalculator.shared.total(from: lineItems, discountPercent: discountPercent)
        subtotalLabel.text = String(format: "Subtotal: $%.2f", subtotal)
        if discountPercent > 0 {
            totalLabel.text = String(format: "Total: $%.2f  (%.1f%% off)", total, discountPercent)
        } else {
            totalLabel.text = String(format: "Total: $%.2f", total)
        }
    }

    @objc private func toggleSelectAll() {
        let allIncluded = lineItems.allSatisfy { $0.isIncluded }
        for i in 0..<lineItems.count {
            lineItems[i].isIncluded = !allIncluded
        }
        tableView.reloadData()
        updateSummary()
        let selectAllBtn = navigationItem.rightBarButtonItems?.last
        selectAllBtn?.title = allIncluded ? "Select All" : "Deselect All"
    }

    @objc private func applyDiscount() {
        let text = discountField.text ?? ""
        discountPercent = Double(text) ?? 0
        discountPercent = max(0, min(100, discountPercent))
        updateSummary()
        view.endEditing(true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func generateCSV(from items: [QuoteLineItem]) -> String {
        let date = DateFormatter.timestampFormatter.string(from: Date())
        return CSVExporter.shared.generateCSV(
            houseName: house.name,
            address: house.address,
            items: items,
            discountPercent: discountPercent
        )
    }

    @objc private func shareTapped() {
        applyDiscount()
        let csv = generateCSV(from: lineItems)
        let date = DateFormatter.timestampFormatter.string(from: Date())
        let safeName = house.name.replacingOccurrences(of: " ", with: "_")
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("quote_\(safeName)_\(date).csv")
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            let vc = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let popover = vc.popoverPresentationController {
                popover.barButtonItem = navigationItem.rightBarButtonItems?.first
            }
            present(vc, animated: true)
        } catch {
            let vc = UIActivityViewController(activityItems: [csv], applicationActivities: nil)
            if let popover = vc.popoverPresentationController {
                popover.barButtonItem = navigationItem.rightBarButtonItems?.first
            }
            present(vc, animated: true)
        }
    }
}

extension QuoteViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lineItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: QuoteLineCell.reuseIdentifier, for: indexPath) as! QuoteLineCell
        let item = lineItems[indexPath.row]
        cell.configure(with: item)
        cell.switchToggleHandler = { [weak self] isOn in
            self?.lineItems[indexPath.row].isIncluded = isOn
            self?.tableView.reloadRows(at: [indexPath], with: .none)
            self?.updateSummary()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return lineItems.isEmpty ? nil : "Items (\(lineItems.count))"
    }
}
