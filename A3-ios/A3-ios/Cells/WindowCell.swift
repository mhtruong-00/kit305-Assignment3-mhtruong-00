// With support from GitHub Copilot
import UIKit

class WindowCell: UITableViewCell {
    static let reuseIdentifier = "WindowCell"

    let infoLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let priceLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = .systemBlue
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let photoIndicator: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGreen
        v.layer.cornerRadius = 5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
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
        contentView.addSubview(infoLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(photoIndicator)
        NSLayoutConstraint.activate([
            photoIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            photoIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            photoIndicator.widthAnchor.constraint(equalToConstant: 10),
            photoIndicator.heightAnchor.constraint(equalToConstant: 10),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: photoIndicator.leadingAnchor, constant: -8),
            priceLabel.widthAnchor.constraint(equalToConstant: 80),
            infoLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8),
            infoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
        accessoryType = .disclosureIndicator
    }

    func configure(with window: WindowItem) {
        let prodStr = window.productName.isEmpty ? "No product" : window.productName
        let varStr = window.variantName.isEmpty ? "" : "\n\(window.variantName)"
        let area = String(format: "%.3f sqm", window.areaSqm)
        infoLabel.text = "\(Int(window.widthCm))W × \(Int(window.heightCm))H cm  [\(area)] — \(prodStr)\(varStr)"
        if window.pricePerSqm > 0 {
            priceLabel.text = String(format: "$%.2f", window.itemPrice)
        } else {
            priceLabel.text = ""
        }
        photoIndicator.isHidden = window.photoBase64 == nil
    }
}
