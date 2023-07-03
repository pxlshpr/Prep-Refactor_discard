import Foundation
import CoreData
import SwiftSugar

class CoreDataManager: NSPersistentContainer {
 
    init() {
        guard
            let url = Bundle.main.url(forResource: "Prep", withExtension: "momd"),
            let objectModel = NSManagedObjectModel(contentsOf: url)
        else {
            fatalError("Failed to retrieve the object model")
        }
        super.init(name: "Prep", managedObjectModel: objectModel)
        self.initialize()
    }
    
    private func initialize() {
        self.loadPersistentStores { description, error in
            if let error {
                fatalError("Failed to load CoreData: \(error)")
            }
        }
    }
    
    func save() throws {
        try self.viewContext.save()
    }
}
