//
//  IconTableView.swift
//  findIcon
//
//  Created by Diana Tsarkova on 13.07.2024.
//

import UIKit

class IconTableViewContainer: UIView {

    let tableView = UITableView(frame: .zero, style: .plain)
    private var viewModel: IconTableViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tableView)
        setupTableView()
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: IconTableViewModel) {
        self.viewModel = viewModel
        self.viewModel?.updateHandler = { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func setupTableView() {
        tableView.accessibilityIdentifier = "IconTableView"
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .interactive
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(IconTableViewCell.self, forCellReuseIdentifier: String(describing: IconTableViewCell.self))
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorInset = .init(top: 0, left: 60, bottom: 0, right: 60)
    }

    private func layout() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension IconTableViewContainer: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.iconModels.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: IconTableViewCell.self), for: indexPath) as? IconTableViewCell,
              let model = viewModel?.iconModels[indexPath.row] else {
            return UITableViewCell()
        }
        cell.configure(iconModel: model)
        cell.switchFavHandler = { [weak viewModel] model in
            viewModel?.switchFavorities(iconModel: model)
        }
        cell.saveIconHandler = { [weak viewModel] iconURL in
            viewModel?.saveToGallery(iconURL: iconURL)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentYOffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYOffset

        guard let viewModel = viewModel else {
            return
        }

        if distanceFromBottom < height && viewModel.iconModels.count % 10 == 0 {
            viewModel.paginationHandler?()
        }
    }
}

