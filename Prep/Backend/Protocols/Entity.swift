import Foundation
import CoreData

protocol Entity: NSManagedObject, Fetchable { }

extension Entity {
    static var entityName : String {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }
    static func countAll(in context: NSManagedObjectContext) -> Int {
        do {
            let request = NSFetchRequest<FetchableType>(entityName: entityName)
            return try context.count(for: request)
        } catch {
            fatalError()
        }
    }
    
    static func objects(
        for predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fetchLimit: Int? = nil,
        in context: NSManagedObjectContext
    ) -> [FetchableType] {
        do {
            let request = NSFetchRequest<FetchableType>(entityName: entityName)
            request.predicate = predicate
            if let fetchLimit {
                request.fetchLimit = fetchLimit
            }
            if let sortDescriptors {
                request.sortDescriptors = sortDescriptors
            }
            return try context.fetch(request)
        } catch {
            fatalError()
        }
    }
    static func object(with id: UUID, in context: NSManagedObjectContext) -> FetchableType? {
        do {
            let request = NSFetchRequest<FetchableType>(entityName: entityName)
            request.predicate = NSPredicate(format: "id == %@", id.uuidString)
            let objects = try context.fetch(request)
            return objects.first
        } catch {
            fatalError()
        }
    }
}
