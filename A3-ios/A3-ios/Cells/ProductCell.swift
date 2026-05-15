// With support from GitHub Copilot
import UIKit

class ProductCell: UITableViewCell {
    static let reuseIdentifier = "ProductCell"

    let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let descriptionLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.textColor = .secondaryLabel
        lbl.numberOfLines = 1
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let priceLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        lbl.textColor = .productTint
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let categoryLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.textColor = .systemBlue
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let compatibilityLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        lbl.numberOfLines = 0
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
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(compatibilityLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            priceLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 3),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            priceLabel.trailingAnchor.constraint(equalTo: categoryLabel.leadingAnchor, constant: -8),
            categoryLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            categoryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            compatibilityLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 3),
            compatibilityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            compatibilityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            compatibilityLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
        accessoryType = .disclosureIndicator
    }

    func configure(with product: Product) {
        configure(with: product, compatibility: nil)
    }

    func configure(with product: Product, compatibility: CompatibilityResult?) {
        nameLabel.text = product.name
        descriptionLabel.text = product.description.isEmpty ? nil : product.description
        descriptionLabel.isHidden = product.description.isEmpty
        priceLabel.text = String(format: "$%.2f / sqm", product.pricePerSqm)
        let varCount = product.variants.count
        if varCount > 0 {
            categoryLabel.text = "\(product.category.capitalized) • \(varCount) variants"
        } else {
            categoryLabel.text = product.category.capitalized
        }

        if let compat = compatibility {
            if compat.compatible {
                compatibilityLabel.text = "✓ \(compat.message)"
                compatibilityLabel.textColor = .systemGreen
                contentView.alpha = 1.0
                accessoryType = .disclosureIndicator
            } else {
                compatibilityLabel.text = "✗ \(compat.message)"
                compatibilityLabel.textColor = .systemRed
                contentView.alpha = 0.45
                accessoryType = .none
            }
        } else {
            compatibilityLabel.text = ""
            contentView.alpha = 1.0
            accessoryType = .disclosureIndicator
        }
    }
}
