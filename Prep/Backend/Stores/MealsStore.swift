import Foundation
import CoreData
import OSLog

private let logger = Logger(subsystem: "MealsStore", category: "")

class MealsStore {
    static let shared = MealsStore()
    
    static func meals(on date: Date) async -> [Meal] {
        await DataManager.shared.day(for: date)?.meals ?? []
    }
    
    static func create(_ name: String, at time: Date, on date: Date) async -> (Meal, Day)? {
        await DataManager.shared.createMeal(name, at: time, on: date)
    }
    
    static func update(_ meal: Meal, name: String, time: Date) async -> (Meal, Day)? {
        await DataManager.shared.updateMeal(meal, name, time)
    }
    
    static func delete(_ meal: Meal) async -> Day? {
        await DataManager.shared.delete(meal)
    }
}

extension DataManager {
    
    func delete(_ meal: Meal) async -> Day? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.delete(meal) { dayEntity in
                        guard let dayEntity else {
                            continuation.resume(returning: nil)
                            return
                        }
                        let day = Day(dayEntity)
                        continuation.resume(returning: day)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error deleting food item: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func updateMeal(_ meal: Meal, _ name: String, _ time: Date) async -> (Meal, Day)? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.updateMeal(meal, name, time) { tuple in
                        guard let tuple else {
                            continuation.resume(returning: nil)
                            return
                        }
                        
                        let meal = Meal(tuple.0)
                        let day = Day(tuple.1)
                        continuation.resume(returning: (meal, day))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error creating meal: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    
    func createMeal(_ name: String, at time: Date, on date: Date) async -> (Meal, Day)? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.createMeal(name, at: time, on: date) { tuple in
                        guard let tuple else {
                            continuation.resume(returning: nil)
                            return
                        }
                        
                        let meal = Meal(tuple.0)
                        let day = Day(tuple.1)
                        continuation.resume(returning: (meal, day))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error creating meal: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}

extension CoreDataManager {
    
    func delete(
        _ meal: Meal,
        _ context: NSManagedObjectContext
    ) throws -> DayEntity {
        guard let mealEntity = MealEntity.object(with: meal.id, in: context),
              let dayEntity = mealEntity.dayEntity,
              let dateString = dayEntity.dateString
        else {
            fatalError()
        }
        
        /// Debug: Saving these so we can access them after the deletion
        let foodEntities = mealEntity.foodItemEntitiesArray
            .compactMap { $0.foodEntity }
            .removingDuplicates()
        
        let foodItems = mealEntity.foodItems
        
        /// This cascades deletions to all children `FoodItems`
        context.delete(mealEntity)

        try context.save()

        /// Debug: Confirm that the FoodItems truly get deleted
        for foodItem in foodItems {
            let foodItemEntity = MealEntity.object(with: foodItem.id, in: context)
            guard foodItemEntity == nil else {
                fatalError()
            }
        }
        
        for foodEntity in foodEntities {
            if let lastFoodItem = FoodItemsStore.latestFoodItemEntity(
                foodID: foodEntity.id!, context: context
            ) {
                foodEntity.lastAmount = lastFoodItem.amount
                foodEntity.lastUsedAt = lastFoodItem.updatedAt
            } else {
                foodEntity.lastAmount = nil
                foodEntity.lastUsedAt = nil
            }
        }
        
        guard let updatedDayEntity = self.dayEntity(dateString: dateString, in: context) else {
            fatalError()
        }
        dayEntity.postFoodItemUpdate(.delete)
        
        return updatedDayEntity
    }

    func delete(
        _ meal: Meal,
        completion: @escaping ((DayEntity?) -> ())
    ) throws {
        Task {
            let bgContext = newBackgroundContext()
            await bgContext.perform {
                do {
                    
                    let dayEntity = try self.delete(meal, bgContext)
                    
                    let observer = NotificationCenter.default.addObserver(
                        forName: .NSManagedObjectContextDidSave,
                        object: bgContext,
                        queue: .main
                    ) { (notification) in
                        self.viewContext.mergeChanges(fromContextDidSave: notification)
                        completion(dayEntity)
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
    
    func createMeal(
        _ name: String,
        at time: Date,
        on date: Date,
        completion: @escaping (((MealEntity, DayEntity)?) -> ())
    ) throws {
        Task {
            let bgContext = newBackgroundContext()
            await bgContext.perform {
                do {
                    let dayEntity: DayEntity = self.fetchOrCreateDay(for: date, in: bgContext)
                    
                    let mealEntity = MealEntity(context: bgContext)
                    mealEntity.id = UUID()
                    mealEntity.name = name
                    mealEntity.timeString = time.timeString
                    mealEntity.largestEnergyInKcal = dayEntity.calculatedLargestEnergyInKcal
                    
                    mealEntity.dayEntity = dayEntity
                    
                    bgContext.insert(mealEntity)
                    
                    let observer = NotificationCenter.default.addObserver(
                        forName: .NSManagedObjectContextDidSave,
                        object: bgContext,
                        queue: .main
                    ) { (notification) in
                        self.viewContext.mergeChanges(fromContextDidSave: notification)
                        completion((mealEntity, dayEntity))
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
    
    func updateMeal(
        _ meal: Meal,
        _ name: String,
        _ time: Date,
        completion: @escaping (((MealEntity, DayEntity)?) -> ())
    ) throws {
        Task {
            let bgContext = newBackgroundContext()
            await bgContext.perform {
                do {
                    guard let mealEntity = MealEntity.object(with: meal.id, in: bgContext) else {
                        return
                    }
                    
                    mealEntity.name = name
                    mealEntity.timeString = time.timeString
                    
                    guard let dayEntity = mealEntity.dayEntity else {
                        fatalError()
                    }
                    
                    let observer = NotificationCenter.default.addObserver(
                        forName: .NSManagedObjectContextDidSave,
                        object: bgContext,
                        queue: .main
                    ) { (notification) in
                        self.viewContext.mergeChanges(fromContextDidSave: notification)
                        completion((mealEntity, dayEntity))
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
}
