// With support from GitHub Copilot
import UIKit

enum WindowEditMode {
    case add
    case edit(WindowItem)
}

class WindowEditViewController: UIViewController {

    var house: House!
    var room: Room!
    var mode: WindowEditMode = .add

    private var selectedProduct: Product?
    private var selectedVariant: ProductVariant?
    private var selectedImage: UIImage?
    private var existingPhotoBase64: String?
    private let photoPicker = PhotoPickerCoordinator()

    // MARK: - Constants

    private let maxDimensionCm: Double = 2000
    private let minDimensionCm: Double = 1

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let widthField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Width (cm)"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .decimalPad
        return tf
    }()

    private let heightField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Height (cm)"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .decimalPad
        return tf
    }()

    private let productLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No product selected"
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.textColor = .secondaryLabel
        return lbl
    }()

    private let selectProductButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Select Window Product", for: .normal)
        return btn
    }()

    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        iv.layer.cornerRadius = 8
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let selectPhotoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Select Photo from Gallery", for: .normal)
        return btn
    }()

    private let removePhotoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Remove Photo", for: .normal)
        btn.setTitleColor(.systemRed, for: .normal)
        btn.isHidden = true
        return btn
    }()

    private let priceLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Item price: —"
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = .secondaryLabel
        return lbl
    }()

    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Save Window", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        photoPicker.delegate = self

        switch mode {
        case .add: title = "Add Window"
        case .edit: title = "Edit Window"
        }

        setupScrollLayout()
        populateIfEditing()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        widthField.addTarget(self, action: #selector(dimensionsChanged), for: .editingChanged)
        heightField.addTarget(self, action: #selector(dimensionsChanged), for: .editingChanged)

        widthField.addDoneInputAccessory(target: self, action: #selector(dismissKeyboard))
        heightField.addDoneInputAccessory(target: self, action: #selector(dismissKeyboard))

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let kbFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let inset = UIEdgeInsets(top: 0, left: 0, bottom: kbFrame.height, right: 0)
        scrollView.contentInset = inset
        scrollView.scrollIndicatorInsets = inset
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupScrollLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        let dimStack = UIStackView(arrangedSubviews: [widthField, heightField])
        dimStack.axis = .horizontal
        dimStack.spacing = 12
        dimStack.distribution = .fillEqually

        photoImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true

        [makeLabel("Dimensions (cm)"), dimStack,
         makeLabel("Product"), productLabel, selectProductButton,
         makeLabel("Photo"), photoImageView, selectPhotoButton, removePhotoButton,
         priceLabel, saveButton
        ].forEach { contentStack.addArrangedSubview($0) }

        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        selectProductButton.addTarget(self, action: #selector(selectProductTapped), for: .touchUpInside)
        selectPhotoButton.addTarget(self, action: #selector(selectPhotoTapped), for: .touchUpInside)
        removePhotoButton.addTarget(self, action: #selector(removePhotoTapped), for: .touchUpInside)
    }

    private func populateIfEditing() {
        guard case .edit(let window) = mode else { return }
        widthField.text = String(format: "%.0f", window.widthCm)
        heightField.text = String(format: "%.0f", window.heightCm)
        existingPhotoBase64 = window.photoBase64
        if let p64 = window.photoBase64, let image = ImageStore.shared.decodeImage(p64) {
            photoImageView.image = image
            removePhotoButton.isHidden = false
        }
        if !window.productId.isEmpty {
            productLabel.text = "\(window.productName) — \(window.variantName)"
            productLabel.textColor = .label
            selectedProduct = Product(id: window.productId, name: window.productName,
                                      pricePerSqm: window.pricePerSqm)
            selectedVariant = ProductVariant(id: window.variantId, name: window.variantName)
            updatePriceLabel()
        }
    }

    private func makeLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        lbl.textColor = .secondaryLabel
        return lbl
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func dimensionsChanged() { updatePriceLabel() }

    private func updatePriceLabel() {
        guard let w = Double(widthField.text ?? ""), let h = Double(heightField.text ?? ""),
              let product = selectedProduct, w > 0, h > 0 else {
            priceLabel.text = "Item price: —"
            return
        }
        let area = (w / 100.0) * (h / 100.0)
        let price = product.pricePerSqm * area
        priceLabel.text = String(format: "Item price: $%.2f (%.4f sqm)", price, area)
    }

    @objc private func selectProductTapped() {
        let vc = ProductListViewController()
        vc.category = "window"
        vc.onProductSelected = { [weak self] product, variant in
            guard let self = self else { return }
            self.selectedProduct = product
            self.selectedVariant = variant
            if let variant = variant {
                self.productLabel.text = "\(product.name) — \(variant.name)"
            } else {
                self.productLabel.text = product.name
            }
            self.productLabel.textColor = .label
            self.updatePriceLabel()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func selectPhotoTapped() {
        photoPicker.presentPicker(from: self)
    }

    @objc private func removePhotoTapped() {
        selectedImage = nil
        existingPhotoBase64 = nil
        photoImageView.image = nil
        removePhotoButton.isHidden = true
    }

    @objc private func saveTapped() {
        guard let widthText = widthField.text, let width = Double(widthText),
              width >= minDimensionCm, width <= maxDimensionCm else {
            showAlert(title: "Validation Error",
                      message: "Width must be between \(Int(minDimensionCm)) and \(Int(maxDimensionCm)) cm.")
            return
        }
        guard let heightText = heightField.text, let height = Double(heightText),
              height >= minDimensionCm, height <= maxDimensionCm else {
            showAlert(title: "Validation Error",
                      message: "Height must be between \(Int(minDimensionCm)) and \(Int(maxDimensionCm)) cm.")
            return
        }

        var photoBase64: String? = existingPhotoBase64
        if let img = selectedImage {
            photoBase64 = ImageStore.shared.encodeImage(img)
        }

        let productId = selectedProduct?.id ?? ""
        let productName = selectedProduct?.name ?? ""
        let pricePerSqm = selectedProduct?.pricePerSqm ?? 0
        let variantId = selectedVariant?.id ?? ""
        let variantName = selectedVariant?.name ?? ""

        switch mode {
        case .add:
            let window = WindowItem(roomId: room.id, widthCm: width, heightCm: height,
                                    productId: productId, variantId: variantId,
                                    productName: productName, variantName: variantName,
                                    pricePerSqm: pricePerSqm, photoBase64: photoBase64)
            FirestoreService.shared.addWindow(window, houseId: house.id, roomId: room.id) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        case .edit(var window):
            window.widthCm = width
            window.heightCm = height
            window.productId = productId
            window.variantId = variantId
            window.productName = productName
            window.variantName = variantName
            window.pricePerSqm = pricePerSqm
            window.photoBase64 = photoBase64
            FirestoreService.shared.updateWindow(window, houseId: house.id, roomId: room.id) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
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

extension WindowEditViewController: PhotoPickerDelegate {
    func photoPickerDidSelectImage(_ image: UIImage) {
        selectedImage = image
        photoImageView.image = image
        removePhotoButton.isHidden = false
    }
    func photoPickerDidCancel() {}
}
