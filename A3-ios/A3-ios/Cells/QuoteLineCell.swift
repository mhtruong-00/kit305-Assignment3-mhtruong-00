// With support from GitHub Copilot
import UIKit

class QuoteLineCell: UITableViewCell {
    static let reuseIdentifier = "QuoteLineCell"

    let includeSwitch: UISwitch = {
        let sw = UISwitch()
        sw.translatesAutoresizingMaskIntoConstraints = false
        return sw
    }()

    let roomLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let descriptionLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let priceLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    var switchToggleHandler: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        selectionStyle = .none
        contentView.addSubview(includeSwitch)
        contentView.addSubview(roomLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            includeSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            includeSwitch.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            priceLabel.widthAnchor.constraint(equalToConstant: 80),
            roomLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            roomLabel.leadingAnchor.constraint(equalTo: includeSwitch.trailingAnchor, constant: 10),
            roomLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8),
            descriptionLabel.topAnchor.constraint(equalTo: roomLabel.bottomAnchor, constant: 2),
            descriptionLabel.leadingAnchor.constraint(equalTo: includeSwitch.trailingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])

        includeSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    @objc private func switchChanged() {
        switchToggleHandler?(includeSwitch.isOn)
    }

    func configure(with item: QuoteLineItem) {
        let typeIcon = item.itemType == .window ? "⬜" : "🟫"
        roomLabel.text = "\(typeIcon) \(item.roomName.uppercased())"
        let varStr = item.variantName.isEmpty ? "" : " — \(item.variantName)"
        let typeStr = item.typeLabel
        descriptionLabel.text = "\(typeStr): \(item.dimensionLabel)\n\(item.productName)\(varStr)"
        priceLabel.text = item.isIncluded ? item.priceLabel : "-"
        priceLabel.textColor = item.isIncluded ? .systemGreen : .secondaryLabel
        includeSwitch.isOn = item.isIncluded
        contentView.alpha = item.isIncluded ? 1.0 : 0.5
    }
}
