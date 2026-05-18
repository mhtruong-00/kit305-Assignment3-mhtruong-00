// With support from GitHub Copilot
import UIKit

enum FloorSpaceEditMode {
    case add
    case edit(FloorSpace)
}

class FloorSpaceEditViewController: UIViewController {

    var house: House!
    var room: Room!
    var mode: FloorSpaceEditMode = .add

    private var selectedProduct: Product?
    private var selectedVariant: ProductVariant?
    private var selectedImage: UIImage?
    private var existingPhotoBase64: String?
    private let photoPicker = PhotoPickerCoordinator()

    // MARK: - Constants (millimetres, matching the Android app)

    private let maxDimensionMm: Int = 20_000
    private let minDimensionMm: Int = 1

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Floor space name (e.g. Main floor)"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .words
        return tf
    }()

    private let widthField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Width (mm)"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        return tf
    }()

    private let lengthField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Depth (mm)"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
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
        btn.setTitle("Select Floor Product", for: .normal)
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
        btn.setTitle("Save Floor Space", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = .systemOrange
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
        case .add: title = "Add Floor Space"
        case .edit: title = "Edit Floor Space"
        }
        navigationItem.backButtonTitle = ""

        setupScrollLayout()
        populateIfEditing()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        widthField.addTarget(self, action: #selector(dimensionsChanged), for: .editingChanged)
        lengthField.addTarget(self, action: #selector(dimensionsChanged), for: .editingChanged)

        widthField.addDoneInputAccessory(target: self, action: #selector(dismissKeyboard))
        lengthField.addDoneInputAccessory(target: self, action: #selector(dismissKeyboard))

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

        let dimStack = UIStackView(arrangedSubviews: [widthField, lengthField])
        dimStack.axis = .horizontal
        dimStack.spacing = 12
        dimStack.distribution = .fillEqually

        photoImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true

        [makeLabel("Name"), nameField,
         makeLabel("Dimensions (mm)"), dimStack,
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
        guard case .edit(let floor) = mode else { return }
        nameField.text = floor.name
        widthField.text = floor.widthMm > 0 ? "\(floor.widthMm)" : ""
        lengthField.text = floor.depthMm > 0 ? "\(floor.depthMm)" : ""
        existingPhotoBase64 = floor.photoBase64
        if let p64 = floor.photoBase64, let image = ImageStore.shared.decodeImage(p64) {
            photoImageView.image = image
            removePhotoButton.isHidden = false
        }
        if !floor.selectedProductId.isEmpty {
            productLabel.text = floor.selectedProductVariant.isEmpty
                ? floor.selectedProductName
                : "\(floor.selectedProductName) — \(floor.selectedProductVariant)"
            productLabel.textColor = .label
            selectedProduct = Product(id: floor.selectedProductId,
                                      name: floor.selectedProductName,
                                      pricePerSqm: 0)
            selectedVariant = ProductVariant(id: "", name: floor.selectedProductVariant)
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
        guard let w = Int(widthField.text ?? ""), let l = Int(lengthField.text ?? ""),
              let product = selectedProduct, w > 0, l > 0 else {
            priceLabel.text = "Item price: —"
            return
        }
        let area = (Double(w) / 1000.0) * (Double(l) / 1000.0)
        let rate = product.pricePerSqm > 0 ? product.pricePerSqm : QuoteCalculator.defaultFloorRate
        let price = rate * area
        priceLabel.text = String(format: "Item price: $%.2f (%.4f sqm)", price, area)
    }

    @objc private func selectProductTapped() {
        let vc = ProductListViewController()
        vc.category = "floor"
        vc.spaceWidthMm = Int(widthField.text ?? "") ?? 0
        vc.spaceHeightMm = Int(lengthField.text ?? "") ?? 0
        vc.onProductSelected = { [weak self] product, variant, _ in
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
        guard let widthText = widthField.text, let width = Int(widthText),
              width >= minDimensionMm, width <= maxDimensionMm else {
            showAlert(title: "Validation Error",
                      message: "Width must be between \(minDimensionMm) and \(maxDimensionMm) mm.")
            return
        }
        guard let lengthText = lengthField.text, let length = Int(lengthText),
              length >= minDimensionMm, length <= maxDimensionMm else {
            showAlert(title: "Validation Error",
                      message: "Depth must be between \(minDimensionMm) and \(maxDimensionMm) mm.")
            return
        }

        let name = nameField.text?.trimmingCharacters(in: .whitespaces).nonEmpty ?? "Unnamed"

        var photoBase64: String? = existingPhotoBase64
        if let img = selectedImage {
            photoBase64 = ImageStore.shared.encodeImage(img)
        }

        let productId = selectedProduct?.id ?? ""
        let productName = selectedProduct?.name ?? ""
        let variantName = selectedVariant?.name ?? ""

        switch mode {
        case .add:
            let floor = FloorSpace(roomId: room.id, name: name,
                                   widthMm: width, depthMm: length,
                                   selectedProductId: productId,
                                   selectedProductName: productName,
                                   selectedProductVariant: variantName,
                                   photoBase64: photoBase64)
            FirestoreService.shared.addFloorSpace(floor) { [weak self] error in
                if let error = error {
                    HapticFeedback.error()
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    HapticFeedback.success()
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        case .edit(var floor):
            floor.name = name
            floor.widthMm = width
            floor.depthMm = length
            floor.selectedProductId = productId
            floor.selectedProductName = productName
            floor.selectedProductVariant = variantName
            floor.photoBase64 = photoBase64
            FirestoreService.shared.updateFloorSpace(floor) { [weak self] error in
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

extension FloorSpaceEditViewController: PhotoPickerDelegate {
    func photoPickerDidSelectImage(_ image: UIImage) {
        selectedImage = image
        photoImageView.image = image
        removePhotoButton.isHidden = false
    }
    func photoPickerDidCancel() {}
}
