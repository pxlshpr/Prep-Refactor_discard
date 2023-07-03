import Foundation
import CoreData

protocol Fetchable {
    associatedtype FetchableType: NSManagedObject = Self
    static var entityName : String { get }
    static func objects(for predicate: NSPredicate?, in context: NSManagedObjectContext) throws -> [FetchableType]
    static func countAll(in context: NSManagedObjectContext) throws -> Int
}
