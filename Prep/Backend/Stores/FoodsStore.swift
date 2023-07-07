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
    
    static func create(_ food: Food) async -> Food? {
        await DataManager.shared.createFood(food)
    }
    
    static func update(_ food: Food) async -> Food? {
        await DataManager.shared.updateFood(food)
    }
}

extension DataManager {
    func createFood(_ food: Food) async -> Food? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.createFood(food) { foodEntity in
                        guard let foodEntity else {
                            continuation.resume(returning: nil)
                            return
                        }
                        let food = Food(foodEntity)
                        continuation.resume(returning: food)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error creating food: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    
    func updateFood(_ food: Food) async -> Food? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.updateFood(food) { foodEntity in
                        guard let foodEntity else {
                            continuation.resume(returning: nil)
                            return
                        }
                        let food = Food(foodEntity)
                        continuation.resume(returning: food)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error updating food: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    
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
    func createFood(
        _ food: Food,
        completion: @escaping ((FoodEntity?) -> ())
    ) throws {
        Task {
            let bgContext = newBackgroundContext()
            await bgContext.perform {
                do {
                    let foodEntity = FoodEntity(
                        context: bgContext,
                        food: food
                    )
                    
                    bgContext.insert(foodEntity)
                    
                    let observer = NotificationCenter.default.addObserver(
                        forName: .NSManagedObjectContextDidSave,
                        object: bgContext,
                        queue: .main
                    ) { (notification) in
                        self.viewContext.mergeChanges(fromContextDidSave: notification)
                        completion(foodEntity)
                    }
                    
                    try bgContext.performAndWait {
                        try bgContext.save()
                    }
                    NotificationCenter.default.removeObserver(observer)

                } catch {
                    logger.error("Error: \(error.localizedDescription, privacy: .public)")
                    completion(nil)
                }
            }
        }
    }
    
    func updateFood(
        _ food: Food,
        completion: @escaping ((FoodEntity?) -> ())
    ) throws {
        Task {
            let bgContext = newBackgroundContext()
            await bgContext.perform {
                do {
                    guard let foodEntity = FoodEntity.object(with: food.id, in: bgContext) else {
                        fatalError()
                    }
                    foodEntity.fill(with: food)
                    
                    let observer = NotificationCenter.default.addObserver(
                        forName: .NSManagedObjectContextDidSave,
                        object: bgContext,
                        queue: .main
                    ) { (notification) in
                        self.viewContext.mergeChanges(fromContextDidSave: notification)
                        completion(foodEntity)
                    }
                    
                    try bgContext.performAndWait {
                        try bgContext.save()
                    }
                    NotificationCenter.default.removeObserver(observer)

                } catch {
                    logger.error("Error: \(error.localizedDescription, privacy: .public)")
                    completion(nil)
                }
            }
        }
    }
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
