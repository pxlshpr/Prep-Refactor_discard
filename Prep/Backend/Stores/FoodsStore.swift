import Foundation
import CoreData
import OSLog

private let logger = Logger(subsystem: "FoodsStore", category: "")

class FoodsStore {
    static let shared = FoodsStore()
    
    /// Fetches the users foods for the page provided
    static func userFoods(page: Int) async -> [Food] {
        await DataManager.shared.userFoods(page: page)
    }
    
}

extension DataManager {
    func userFoods(page: Int) async -> [Food] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.userFoodEntities(page: page) { foodEntities in
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
    func userFoodEntities(page: Int, completion: @escaping (([FoodEntity]) -> ())) throws {
        Task {
            let bgContext = newBackgroundContext()
            await bgContext.perform {
                let entities = FoodEntity.objects(
                    predicate: NSPredicate(format: "datasetValue == 0"),
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
