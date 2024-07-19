//
//  IconTableViewCell.swift
//  findIcon
//
//  Created by Diana Tsarkova on 01.07.2024.
//

import UIKit

class IconTableViewCell: UITableViewCell {

    static let imageHeight: CGFloat = 70

    var switchFavHandler: ((IconModel) -> Void)?
    var saveIconHandler: ((String) -> Void)?

    private let iconImage = UIImageView()
    private let sizeLabel = UILabel()
    private let tagsLabel = UILabel()
    private let actionButton = UIButton()

    private var iconModel: IconModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
        layout()
    }

    func configure(iconModel: IconModel) {
        self.iconModel = iconModel
        sizeLabel.text = iconModel.maxSize
        tagsLabel.text = iconModel.tags
        actionButton.setImage(iconModel.isFav ? .heart : .emptyHeart, for: .normal)
        DispatchQueue(label: "com.findIcon.requests", qos: .userInitiated).async { [weak self] in
            guard let urlStr = iconModel.previewURL,
                  let url = URL(string: urlStr) else { return }
            self?.iconImage.load(url: url, placeholder: .placeholder)
        }
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(iconImage)
        contentView.addSubview(sizeLabel)
        contentView.addSubview(tagsLabel)
        contentView.addSubview(actionButton)
        setupIconImage()
        setupSizeLabel()
        setupTagsLabel()
        setupActionButton()
    }

    private func setupIconImage() {
        iconImage.accessibilityIdentifier = "iconImage"
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        iconImage.contentMode = .scaleAspectFit
        iconImage.image = .placeholder
        iconImage.isUserInteractionEnabled = true
        iconImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(saveToGallery)))
    }

    private func setupSizeLabel() {
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        sizeLabel.numberOfLines = 1
        sizeLabel.textAlignment = .center
    }

    private func setupTagsLabel() {
        tagsLabel.translatesAutoresizingMaskIntoConstraints = false
        tagsLabel.numberOfLines = 2
        tagsLabel.textAlignment = .center
        tagsLabel.lineBreakMode = .byWordWrapping
    }

    private func setupActionButton() {
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(addToFavorities), for: .touchUpInside)
    }

    private func layout() {
        NSLayoutConstraint.activate([
            iconImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            iconImage.heightAnchor.constraint(equalToConstant: IconTableViewCell.imageHeight),
            iconImage.widthAnchor.constraint(equalToConstant: IconTableViewCell.imageHeight),
            iconImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            iconImage.bottomAnchor.constraint(equalTo: sizeLabel.topAnchor, constant: -4),

            sizeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sizeLabel.topAnchor.constraint(equalTo: iconImage.bottomAnchor, constant: 4),
            sizeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sizeLabel.bottomAnchor.constraint(equalTo: tagsLabel.topAnchor, constant: -4),

            tagsLabel.topAnchor.constraint(equalTo: sizeLabel.bottomAnchor, constant: 4),
            tagsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tagsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tagsLabel.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -4),

            actionButton.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -21),
            actionButton.widthAnchor.constraint(equalToConstant: 36),
            actionButton.heightAnchor.constraint(equalToConstant: 36),
            actionButton.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: 8),
            actionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    @objc
    func addToFavorities() {
        let isOldFav = iconModel?.isFav ?? false
        iconModel?.isFav = !isOldFav
        guard let iconModel = iconModel else {
            return
        }
        switchFavHandler?(iconModel)
        actionButton.setImage(iconModel.isFav ? .heart : .emptyHeart, for: .normal)
    }

    @objc
    func saveToGallery() {
        guard let icon = iconModel?.iconURL else {
            return
        }
        saveIconHandler?(icon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension UIImageView {
    func load(url: URL, placeholder: UIImage?, cache: URLCache? = nil) {
        IconTableViewModel.load(url: url, cache: cache) { [weak self] image in
            guard let image = image else {
                DispatchQueue.main.async {
                    self?.image = placeholder
                }
                return
            }
            DispatchQueue.main.async {
                self?.image = image
            }
        }
    }
}
