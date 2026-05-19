// With support from GitHub Copilot
import UIKit

enum HouseEditMode {
    case add
    case edit(House)
}

class HouseEditViewController: UIViewController {

    var mode: HouseEditMode = .add
    var onSave: (() -> Void)?

    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Customer / House Name"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .words
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let addressField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Address"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .words
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let notesView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 15)
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.cornerRadius = 6
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let notesPlaceholder: UILabel = {
        let lbl = UILabel()
        lbl.text = "e.g. preferred install date, style preferences, contact details…"
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = .placeholderText
        lbl.numberOfLines = 0
        lbl.isUserInteractionEnabled = false      // let taps pass through to the UITextView
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Save", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Cancel", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        populateIfEditing()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false          // don't swallow taps meant for text fields/views
        view.addGestureRecognizer(tap)
    }

    private func setupUI() {
        switch mode {
        case .add: title = "Add House"
        case .edit: title = "Edit House"
        }

        let nameLabel = makeLabel("Customer / House Name")
        let addressLabel = makeLabel("Address")
        let notesLabel = makeLabel("Notes (optional)")

        view.addSubview(nameLabel)
        view.addSubview(nameField)
        view.addSubview(addressLabel)
        view.addSubview(addressField)
        view.addSubview(notesLabel)
        view.addSubview(notesView)
        notesView.addSubview(notesPlaceholder)
        view.addSubview(saveButton)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nameField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nameField.heightAnchor.constraint(equalToConstant: 44),
            addressLabel.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
            addressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addressField.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 6),
            addressField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addressField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addressField.heightAnchor.constraint(equalToConstant: 44),

            notesLabel.topAnchor.constraint(equalTo: addressField.bottomAnchor, constant: 16),
            notesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            notesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            notesView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 6),
            notesView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            notesView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            notesView.heightAnchor.constraint(equalToConstant: 110),
            notesPlaceholder.topAnchor.constraint(equalTo: notesView.topAnchor, constant: 8),
            notesPlaceholder.leadingAnchor.constraint(equalTo: notesView.leadingAnchor, constant: 6),
            notesPlaceholder.trailingAnchor.constraint(equalTo: notesView.trailingAnchor, constant: -6),

            saveButton.topAnchor.constraint(equalTo: notesView.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        notesView.delegate = self
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }

    private func populateIfEditing() {
        if case .edit(let house) = mode {
            nameField.text = house.name
            addressField.text = house.address
            notesView.text = house.notes
            notesPlaceholder.isHidden = !house.notes.isEmpty
        }
    }

    private func makeLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func saveTapped() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            nameField.becomeFirstResponder()
            showAlert(title: "Name Required", message: "Please enter a customer name before saving.")
            HapticFeedback.error()
            return
        }
        let trimmedName = name
        let address = addressField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        // Match the Android validation: address required AND must contain at least one letter
        // (prevents numeric-only entries like "12345").
        if address.isEmpty {
            addressField.becomeFirstResponder()
            showAlert(title: "Address Required", message: "Please enter an address.")
            HapticFeedback.error()
            return
        }
        if !address.contains(where: { $0.isLetter }) {
            addressField.becomeFirstResponder()
            showAlert(title: "Invalid Address", message: "Address must contain at least one letter.")
            HapticFeedback.error()
            return
        }

        switch mode {
        case .add:
            let house = House(name: trimmedName, address: address, notes: notesView.text ?? "")
            FirestoreService.shared.addHouse(house) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    HapticFeedback.success()
                    self?.onSave?()
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        case .edit(var house):
            house.name = trimmedName
            house.address = address
            house.notes = notesView.text ?? ""
            FirestoreService.shared.updateHouse(house) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    HapticFeedback.success()
                    self?.onSave?()
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension HouseEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        notesPlaceholder.isHidden = !(textView.text ?? "").isEmpty
    }
}
