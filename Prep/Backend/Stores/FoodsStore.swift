import Foundation
import CoreData
import OSLog

private let logger = Logger(subsystem: "FoodsStore", category: "")

class FoodsStore {
    static let shared = FoodsStore()
    
    static func foods(page: Int) async -> [Food] {
        await DataManager.shared.foods(page: page)
    }
    
}

extension DataManager {
    func foods(page: Int) async -> [Food] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.foodEntities(page: page) { foodEntities in
                        let foods = foodEntities.map { Food($0) }
                        continuation.resume(returning: foods)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error fetching foods: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
}

extension CoreDataManager {
    func foodEntities(page: Int, completion: @escaping (([FoodEntity]) -> ())) throws {
        Task {
            let bgContext = newBackgroundContext()
            await bgContext.perform {
                let entities = FoodEntity.objects(
                    predicate: NSPredicate(format: "datasetValue == nil"),
                    sortDescriptors: [
                        NSSortDescriptor(keyPath: \FoodEntity.name, ascending: true),
                        NSSortDescriptor(keyPath: \FoodEntity.detail, ascending: true),
                        NSSortDescriptor(keyPath: \FoodEntity.brand, ascending: true),
                    ],
                    fetchLimit: FoodPageSize,
                    fetchOffset: (page - 1) * FoodPageSize,
                    context: bgContext
                )
                completion(entities)
            }
        }
    }
}
