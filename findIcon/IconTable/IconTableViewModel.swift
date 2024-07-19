//
//  IconTableViewModel.swift
//  findIcon
//
//  Created by Diana Tsarkova on 13.07.2024.
//

import Foundation
import CoreData
import UIKit.UIImage

class IconTableViewModel {
    // Use in view model. Realize in table view
    var updateHandler: (() -> Void)?
    // Use in table view. Realize in view model
    var paginationHandler: (() -> Void)?
    // Use in controller for UIImageWriteToSavedPhotosAlbum
    var savingImageHandler: ((UIImage?) -> Void)?

    var iconModels: [IconModel] = []

    func saveToGallery(iconURL: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let validURL = URL(string: iconURL) else {
                self?.savingImageHandler?(nil)
                return
            }
            IconTableViewModel.load(url: validURL) { [weak self] image in
                self?.savingImageHandler?(image)
            }
        }
    }

    func switchFavorities(iconModel: IconModel) {
        if iconModel.isFav {
            if !checkRestriction() {
                makeRestriction()
            }
            saveToFavorities(iconModel: iconModel)
        } else {
            deleteFromFavorities(iconModel: iconModel)
        }
    }

    func checkRestriction() -> Bool {
        let fetchRequest = UserIcon.fetchRequest()
        guard let count = try? CoreDataHelper.shared.mainManagedObjectContext.count(for: fetchRequest) else {
            return false
        }
        return count < 10
    }

    func makeRestriction() {
        DispatchQueue(label: "CoreData").async {
            let fetchRequest = UserIcon.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "create_date", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            fetchRequest.fetchLimit = 1
            CoreDataHelper.shared.mainManagedObjectContext.performAndWait {
                guard let object = try? CoreDataHelper.shared.mainManagedObjectContext.fetch(fetchRequest).first else {
                    print("Error: Find first created UserIcon object failed")
                    return
                }
                UserDefaults.standard.setValue(false, forKey: String(object.iconId))
                CoreDataHelper.shared.mainManagedObjectContext.delete(object)
                do { try CoreDataHelper.shared.mainManagedObjectContext.save() }
                catch { print("Saving context error") }
            }
        }
    }

    func saveToFavorities(iconModel: IconModel) {
        DispatchQueue(label: "CoreData").async {
            guard let managedObject = NSEntityDescription.insertNewObject(
                forEntityName: "UserIcon",
                into: CoreDataHelper.shared.mainManagedObjectContext
            ) as? UserIcon
            else {
                print("UserIcon entity creating error")
                return
            }
            managedObject.setValuesForKeys(iconModel.dictionary)
            managedObject.setValue(Date(), forKey: "create_date")
            CoreDataHelper.shared.saveData(objects: [managedObject])
        }
    }

    func deleteFromFavorities(iconModel: IconModel) {
        DispatchQueue(label: "CoreData").async {
            if let id = iconModel.iconId,
               let icon = CoreDataHelper.shared.retrieve(name: "UserIcon", propertyCondition: String(id)) {
                CoreDataHelper.shared.deleteData(objects: [icon])
                print("Icon with id '\(id)' deleted.")
            } else {
                print("Icon with id '\(iconModel.iconId ?? 0)' not found for deletion.")
            }
        }
    }
}

extension IconTableViewModel {
    static func load(url: URL, cache: URLCache? = nil, _ completion: @escaping ((UIImage?) -> Void)) {
        let cache = cache ?? URLCache.shared
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "Authorization": "Bearer ZsizyvuuwptYc7PY1KduTqDlSVKF7CecaLDYmneBy08vJSGoVlYD2IxkRKuQlDo9"
        ]

        if let data = cache.cachedResponse(for: request)?.data, let image = UIImage(data: data) {
            completion(image)
        } else {
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data,
                      let httpResponse = response as? HTTPURLResponse,
                      200...299 ~= httpResponse.statusCode,
                      let image = UIImage(data: data) else {
                    completion(nil)
                    return
                }
                let cachedData = CachedURLResponse(response: httpResponse, data: data)
                cache.storeCachedResponse(cachedData, for: request)
                completion(image)
            }.resume()
        }
    }
}
