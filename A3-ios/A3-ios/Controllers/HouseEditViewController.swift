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
        tf.placeholder = "Address (optional)"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .words
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
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
        view.addGestureRecognizer(tap)
    }

    private func setupUI() {
        switch mode {
        case .add: title = "Add House"
        case .edit: title = "Edit House"
        }

        let nameLabel = makeLabel("Customer / House Name")
        let addressLabel = makeLabel("Address")

        view.addSubview(nameLabel)
        view.addSubview(nameField)
        view.addSubview(addressLabel)
        view.addSubview(addressField)
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
            saveButton.topAnchor.constraint(equalTo: addressField.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }

    private func populateIfEditing() {
        if case .edit(let house) = mode {
            nameField.text = house.name
            addressField.text = house.address
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
        guard let name = nameField.text, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(title: "Validation Error", message: "House name is required.")
            return
        }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let address = addressField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        switch mode {
        case .add:
            let house = House(name: trimmedName, address: address)
            FirestoreService.shared.addHouse(house) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    HapticFeedback.success()
                    self?.onSave?()
                    self?.navigationController?.popViewController(animated: true)
            house.name = trimmedName
            house.address = address
            FirestoreService.shared.updateHouse(house) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
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
