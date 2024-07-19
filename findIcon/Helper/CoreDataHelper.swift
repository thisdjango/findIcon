//
//  CoreDataHelper.swift
//  findIcon
//
//  Created by Diana Tsarkova on 07.07.2024.
//

import CoreData
import UIKit

extension UserIcon {
    func toIconModel() -> IconModel {
        return IconModel(
            id: Int(iconId),
            previewURL: previewURL,
            iconURL: iconURL,
            maxSize: maxSize,
            tags: tags ?? ""
        )
    }
}

class CoreDataHelper {
    static let shared = CoreDataHelper()

    lazy var mainManagedObjectContext: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()

    private func saveMainContext() {
        if mainManagedObjectContext.hasChanges {
            do {
                try mainManagedObjectContext.save()
            } catch {
                print("Error saving main managed object context: \(error)")
            }
        }
    }

    private func saveChanges() {
        saveMainContext()
    }

    func retrieve<T: NSManagedObject>(name: String, formatCondition: String = "iconId == %@", propertyCondition: String) -> T? {
        let fetchRequest = NSFetchRequest<T>(entityName: name)

        fetchRequest.predicate = NSPredicate(format: formatCondition, propertyCondition)
        fetchRequest.fetchLimit = 1

        var objects = [T]()
        CoreDataHelper.shared.mainManagedObjectContext.performAndWait {
            do {
                objects = try CoreDataHelper.shared.mainManagedObjectContext.fetch(fetchRequest)
            } catch {
                print("Error fetching specific data: \(error)")
            }
        }
        return objects.first
    }

    func saveData<T: NSManagedObject>(objects: [T]) {
        mainManagedObjectContext.perform {
            // Insert the objects into the private context
            for object in objects {
                self.mainManagedObjectContext.insert(object)
            }

            // Save changes to the private context and merge to the main context
            self.saveChanges()
        }
    }

    func updateData<T: NSManagedObject>(objects: [T]) {
        mainManagedObjectContext.perform {
            // Update the objects in the private context
            for object in objects {
                if object.managedObjectContext == self.mainManagedObjectContext {
                    // If the object is already in the private context, update it directly
                    object.managedObjectContext?.refresh(object, mergeChanges: true)
                } else {
                    // If the object is not in the private context, fetch and update it
                    let fetchRequest = NSFetchRequest<T>(entityName: object.entity.name!)
                    fetchRequest.predicate = NSPredicate(format: "SELF == %@", object)
                    fetchRequest.fetchLimit = 1

                    if let fetchedObject = try? self.mainManagedObjectContext.fetch(fetchRequest).first {
                        fetchedObject.setValuesForKeys(object.dictionaryWithValues(forKeys: Array(object.entity.attributesByName.keys)))
                    }
                }
            }

            // Save changes to the private context and merge to the main context
            self.saveChanges()
        }
    }

    func deleteData<T: NSManagedObject>(objects: [T]) {
        mainManagedObjectContext.perform {
            // Delete the objects from the private context
            for object in objects {
                if object.managedObjectContext == self.mainManagedObjectContext {
                    self.mainManagedObjectContext.delete(object)
                } else {
                    if let objectInContext = self.mainManagedObjectContext.object(with: object.objectID) as? T {
                        self.mainManagedObjectContext.delete(objectInContext)
                    }
                }
            }

            // Save changes to the private context and merge to the main context
            self.saveChanges()
        }
    }
}
