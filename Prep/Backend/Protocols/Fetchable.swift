import Foundation
import CoreData

protocol Fetchable {
    associatedtype FetchableType: NSManagedObject = Self
    static var entityName : String { get }
    static func objects(for predicate: NSPredicate?, in context: NSManagedObjectContext) -> [FetchableType]
    static func countAll(in context: NSManagedObjectContext) -> Int
    static func object(with id: UUID, in context: NSManagedObjectContext) -> FetchableType?
}
