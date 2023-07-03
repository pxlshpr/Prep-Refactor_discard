import Foundation
import CoreData

protocol Entity: NSManagedObject, Fetchable { }

extension Entity {
    static var entityName : String {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }
    static func countAll(in context: NSManagedObjectContext) throws -> Int {
        let request = NSFetchRequest<FetchableType>(entityName: entityName)
        return try context.count(for: request)
    }
    static func objects(for predicate: NSPredicate?, in context: NSManagedObjectContext) throws -> [FetchableType] {
        let request = NSFetchRequest<FetchableType>(entityName: entityName)
        request.predicate = predicate
        return try context.fetch(request)
    }
}
