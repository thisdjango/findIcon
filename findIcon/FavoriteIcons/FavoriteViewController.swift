//
//  FavoriteViewController.swift
//  iconSearch
//
//  Created by Diana Tsarkova on 30.06.2024.
//

import UIKit
import CoreData

class FavoriteViewController: UIViewController {

    private var viewModel = IconTableViewModel()
    private let tableViewContainer = IconTableViewContainer()
    private var fetchedResultsController: NSFetchedResultsController<UserIcon>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(tableViewContainer)
        setupTable()
        setupViewModel()
        layout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        tableViewContainer.tableView.reloadData()
    }

    private func setupTable() {
        tableViewContainer.configure(viewModel: viewModel)
        tableViewContainer.translatesAutoresizingMaskIntoConstraints = false
        tableViewContainer.tableView.dataSource = self
        tableViewContainer.tableView.delegate = self
    }

    func setupViewModel() {
        viewModel.savingImageHandler = { [weak self] image in
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

    private func layout() {
        NSLayoutConstraint.activate([
            tableViewContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 42),
            tableViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableViewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadData() {
        if fetchedResultsController == nil {
            let fetchRequest: NSFetchRequest<UserIcon> = UserIcon.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "create_date", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]

            fetchedResultsController = NSFetchedResultsController<UserIcon>(
                fetchRequest: fetchRequest,
                managedObjectContext: CoreDataHelper.shared.mainManagedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            fetchedResultsController?.delegate = self
        }

        do {
            try fetchedResultsController?.performFetch()
            viewModel.updateHandler?()
        } catch {
            showAlert(message: .fetchError)
        }
    }
}

extension FavoriteViewController {
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(title: .saveImageError, message: error.localizedDescription)
        } else {
            showAlert(title: .saveImageSuccess, message: .saveImageSuccessMessage)
        }
    }
}

extension FavoriteViewController: UITableViewDelegate, UITableViewDataSource {
    // Get the number of sections in the table view from the fetched results
    // controller.
    func numberOfSections(in tableView: UITableView) -> Int {
        fetchedResultsController?.sections?.count ?? 0
    }

    // Get the number of rows in each section of the table view from the fetched results controller.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController?.sections?[section] else {
            return 0
        }

        return sectionInfo.numberOfObjects
    }

    // Get table view cells for index paths from the fetched results controller.
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: IconTableViewCell.self), for: indexPath) as? IconTableViewCell,
              let item = fetchedResultsController?.object(at: indexPath)
        else {
            return UITableViewCell()
        }

        cell.configure(iconModel: item.toIconModel())
        cell.switchFavHandler = { model in
            guard let iconId = model.iconId, item.iconId == iconId else { return }
            CoreDataHelper.shared.deleteData(objects: [item])
            DispatchQueue.main.async {
                tableView.reloadData()
            }
        }
        cell.saveIconHandler = { [weak viewModel] iconURL in
            viewModel?.saveToGallery(iconURL: iconURL)
        }
        return cell
    }

    // Get the title of the header for the specified table view section from the
    // fetched results controller.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = fetchedResultsController?.sections?[section] else {
            return nil
        }

        return sectionInfo.name
    }

    // Get the section index titles from the fetched results controller.
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        fetchedResultsController?.sectionIndexTitles
    }

    // Get the section for the specified index title from the fetched
    // results controller.
    func tableView(_ tableView: UITableView,
                   sectionForSectionIndexTitle title: String,
                   at index: Int) -> Int {
        guard let result = fetchedResultsController?.section(forSectionIndexTitle: title,
                                                             at: index) else {
            fatalError("Failed to locate section for \(title) at index \(index)")
        }

        return result
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let object = fetchedResultsController?.object(at: indexPath) else { return }
            var model = object.toIconModel()
            model.isFav = false
            CoreDataHelper.shared.deleteData(objects: [object])
            DispatchQueue.main.async {
                tableView.reloadData()
            }
        }
    }
}

extension FavoriteViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return sectionName
    }

    func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        DispatchQueue.main.async { [weak self] in
            switch type {
            case .insert:
                self?.tableViewContainer.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                self?.tableViewContainer.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
            }
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        DispatchQueue.main.async { [weak self] in
            guard self?.tabBarController?.selectedViewController == self else {
                return
            }
            self?.tableViewContainer.tableView.performBatchUpdates({
                switch type {
                case .insert:
                    if let indexPath = newIndexPath {
                        self?.tableViewContainer.tableView.insertRows(at: [indexPath as IndexPath], with: .automatic)
                    }
                case .update:
                    if let indexPath = indexPath {
                        self?.tableViewContainer.tableView.reloadRows(at: [indexPath as IndexPath], with: .automatic)
                    }
                case .move:
                    if let indexPath = indexPath {
                        self?.tableViewContainer.tableView.deleteRows(at: [indexPath as IndexPath], with: .automatic)
                    }
                    if let newIndexPath = newIndexPath {
                        self?.tableViewContainer.tableView.insertRows(at: [newIndexPath as IndexPath], with: .automatic)
                    }
                case .delete:
                    if let indexPath = indexPath {
                        self?.tableViewContainer.tableView.deleteRows(at: [indexPath as IndexPath], with: .automatic)
                    }
                @unknown default:
                    fatalError()
                }
            })
        }
    }
}
