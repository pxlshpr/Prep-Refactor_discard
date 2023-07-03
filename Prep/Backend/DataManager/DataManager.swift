import Foundation
import CoreData

class DataManager: ObservableObject {
    
    static let shared = DataManager()
    let coreDataManager: CoreDataManager
    
    convenience init() {
        self.init(coreDataManager: CoreDataManager())
        coreDataManager.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    public static var context: NSManagedObjectContext {
        shared.coreDataManager.viewContext
    }
}

extension DataManager {
    static func populateIfNeeded() {
        shared.coreDataManager.populateIfNeeded()
    }
}
