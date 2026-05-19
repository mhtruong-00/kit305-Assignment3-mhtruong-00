// With support from GitHub Copilot
import UIKit

class HouseCell: UITableViewCell {
    static let reuseIdentifier = "HouseCell"

    let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let addressLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = .secondaryLabel
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    /// Tappable 📝 indicator when the house has any notes attached. Tap to edit notes.
    let notesIndicator: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "note.text"), for: .normal)
        btn.tintColor = .quoteTint
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)  // bigger hit target
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// Called when the notes button is tapped (so the row tap can still navigate to rooms).
    var onNotesTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        notesIndicator.addTarget(self, action: #selector(notesButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        notesIndicator.addTarget(self, action: #selector(notesButtonTapped), for: .touchUpInside)
    }

    @objc private func notesButtonTapped() {
        onNotesTapped?()
    }

    private func setupViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(notesIndicator)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: notesIndicator.leadingAnchor, constant: -8),
            notesIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            notesIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            notesIndicator.widthAnchor.constraint(equalToConstant: 34),
            notesIndicator.heightAnchor.constraint(equalToConstant: 34),
            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            addressLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            addressLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            addressLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
        accessoryType = .disclosureIndicator
    }

    func configure(with house: House) {
        nameLabel.text = house.name.isEmpty ? "Unnamed Customer" : house.name
        addressLabel.text = house.address.isEmpty ? "No address" : house.address
        notesIndicator.isHidden = house.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
