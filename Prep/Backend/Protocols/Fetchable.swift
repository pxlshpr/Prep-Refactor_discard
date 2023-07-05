import Foundation
import CoreData

protocol Fetchable {
    associatedtype FetchableType: NSManagedObject = Self
    static var entityName : String { get }
    
    static func countAll(in context: NSManagedObjectContext) -> Int
    static func object(with id: UUID, in context: NSManagedObjectContext) -> FetchableType?
    
    static func objects(
        for predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor]?,
        fetchLimit: Int?,
        in context: NSManagedObjectContext
    ) -> [FetchableType]
}
