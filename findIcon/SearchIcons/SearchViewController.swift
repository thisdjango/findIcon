//
//  SearchViewController.swift
//  iconSearch
//
//  Created by Diana Tsarkova on 30.06.2024.
//

import UIKit

class SearchViewController: UIViewController {

    private let viewModel = SearchViewModel()

    private let textField = UITextField()
    private let searchButton = UIButton(type: .system)
    private let tableViewContainer = IconTableViewContainer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        layout()
        searchAction()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableViewContainer.tableView.reloadData()
    }

    private func setup() {
        view.addSubview(textField)
        view.addSubview(searchButton)
        view.addSubview(tableViewContainer)
        setupTextField()
        setupSearchButton()
        setupTable()
        setupViewModel()
    }

    private func setupViewModel() {
        viewModel.errorHandler = { [weak self] message in
            self?.showAlert(message: message)
        }
        viewModel.tableViewModel.savingImageHandler = { [weak self] image in
            guard let image = image else {
                DispatchQueue.main.async {
                    self?.showAlert(message: .loadImageError)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }

    private func setupTextField() {
        textField.returnKeyType = .search
        textField.delegate = self
        textField.placeholder = .findIcon
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }

    private func setupSearchButton() {
        searchButton.setTitle(.find, for: .normal)
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.backgroundColor = .link
        searchButton.clipsToBounds = false
        searchButton.layer.cornerRadius = 10
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
    }

    private func setupTable() {
        tableViewContainer.translatesAutoresizingMaskIntoConstraints = false
        tableViewContainer.configure(viewModel: viewModel.tableViewModel)
    }

    private func layout() {
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.heightAnchor.constraint(equalToConstant: 36),

            searchButton.topAnchor.constraint(equalTo: textField.topAnchor),
            searchButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 6),
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchButton.widthAnchor.constraint(equalToConstant: 70),
            searchButton.heightAnchor.constraint(equalToConstant: 36),

            tableViewContainer.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 12),
            tableViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableViewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc
    func searchAction() {
        viewModel.clear()
        textFieldDidEndEditing(textField)
    }
}

extension SearchViewController {
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(title: .saveImageError, message: error.localizedDescription)
        } else {
            showAlert(title: .saveImageSuccess, message: .saveImageSuccessMessage)
        }
    }
}

extension SearchViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }
        viewModel.searchIcon(text: text)
    }
}
