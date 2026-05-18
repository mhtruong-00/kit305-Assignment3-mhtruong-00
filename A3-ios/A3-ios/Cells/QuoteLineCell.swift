// With support from GitHub Copilot
import UIKit

class QuoteLineCell: UITableViewCell {
    static let reuseIdentifier = "QuoteLineCell"

    let includeSwitch: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = .quoteTint
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
        lbl.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let defaultRateBadge: PaddedLabel = {
        let lbl = PaddedLabel()
        lbl.text = "default rate"
        lbl.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        lbl.textColor = .secondaryLabel
        lbl.backgroundColor = .tertiarySystemFill
        lbl.layer.cornerRadius = 4
        lbl.layer.masksToBounds = true
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
        contentView.addSubview(defaultRateBadge)

        NSLayoutConstraint.activate([
            includeSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            includeSwitch.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),

            priceLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            priceLabel.widthAnchor.constraint(equalToConstant: 90),

            defaultRateBadge.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 2),
            defaultRateBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

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
        let namePart = item.itemName.isEmpty ? "" : " “\(item.itemName)”"
        descriptionLabel.text = "\(typeStr)\(namePart): \(item.dimensionLabel)\n\(item.productName)\(varStr)"
        priceLabel.text = item.isIncluded ? item.priceLabel : "—"
        priceLabel.textColor = item.isIncluded ? .systemGreen : .tertiaryLabel
        includeSwitch.isOn = item.isIncluded
        contentView.alpha = item.isIncluded ? 1.0 : 0.5
        defaultRateBadge.isHidden = !item.usedDefaultRate
    }
}

/// Small inset label used for tag/badge styling.
final class PaddedLabel: UILabel {
    var insets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }
}
