// With support from GitHub Copilot
import UIKit

class RoomCell: UITableViewCell {
    static let reuseIdentifier = "RoomCell"

    let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 6
        iv.backgroundColor = .secondarySystemFill
        iv.tintColor = .systemGray3
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 17, weight: .medium)
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
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            thumbnailView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 44),
            thumbnailView.heightAnchor.constraint(equalToConstant: 44),
            nameLabel.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
        accessoryType = .disclosureIndicator
    }

    func configure(with room: Room) {
        nameLabel.text = room.name.isEmpty ? "Unnamed Room" : room.name
        if let b64 = room.photoBase64, let img = ImageStore.shared.decodeImage(b64) {
            thumbnailView.image = img
            thumbnailView.contentMode = .scaleAspectFill
        } else {
            thumbnailView.image = UIImage(systemName: "door.left.hand.closed")
            thumbnailView.contentMode = .center
        }
    }
}
