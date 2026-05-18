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

    /// Small 📝 indicator when the house has any notes attached.
    let notesIndicator: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "note.text"))
        iv.tintColor = .quoteTint
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
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
        contentView.addSubview(addressLabel)
        contentView.addSubview(notesIndicator)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: notesIndicator.leadingAnchor, constant: -8),
            notesIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            notesIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            notesIndicator.widthAnchor.constraint(equalToConstant: 18),
            notesIndicator.heightAnchor.constraint(equalToConstant: 18),
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
