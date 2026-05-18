// With support from GitHub Copilot
import UIKit

class WindowCell: UITableViewCell {
    static let reuseIdentifier = "WindowCell"

    let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 6
        iv.backgroundColor = .secondarySystemFill
        iv.tintColor = .windowTint
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    let infoLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let priceLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        lbl.textColor = .systemGreen
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        contentView.addSubview(thumbnailView)
        contentView.addSubview(infoLabel)
        contentView.addSubview(priceLabel)
        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            thumbnailView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 48),
            thumbnailView.heightAnchor.constraint(equalToConstant: 48),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            priceLabel.widthAnchor.constraint(equalToConstant: 80),
            infoLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            infoLabel.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8),
            infoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
        accessoryType = .disclosureIndicator
    }

    func configure(with window: WindowItem) {
        var prodStr = window.selectedProductName.isEmpty ? "No product" : window.selectedProductName
        if window.panelCount > 1 {
            prodStr += " (\(window.panelCount) panels)"
        }
        let varStr = window.selectedProductVariant.isEmpty ? "" : "\n\(window.selectedProductVariant)"
        let area = String(format: "%.3f sqm", window.areaSqm)
        let namePrefix = window.name.isEmpty ? "" : "\(window.name): "
        infoLabel.text = "\(namePrefix)\(window.widthMm)W × \(window.heightMm)H mm  [\(area)] — \(prodStr)\(varStr)"
        priceLabel.text = ""

        if let b64 = window.photoBase64, let img = ImageStore.shared.decodeImage(b64) {
            thumbnailView.image = img
            thumbnailView.contentMode = .scaleAspectFill
        } else {
            thumbnailView.image = UIImage(systemName: "rectangle.split.2x1")
            thumbnailView.contentMode = .center
        }
    }
}
