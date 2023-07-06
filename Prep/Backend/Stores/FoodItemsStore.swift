import Foundation
import CoreData
import OSLog

private let logger = Logger(subsystem: "FoodItems", category: "")

class FoodItemsStore {
    static let shared = FoodItemsStore()
    
    /// Creates a new `FoodItem` and returns the updated `Day` (so that this may passed on in a notification for UI updates)
    static func create(_ food: Food, meal: Meal, amount: FoodValue) async -> (FoodItem, Day)? {
        await DataManager.shared.createFoodItem(food, meal: meal, amount: amount)
    }

    static func update(_ foodItem: FoodItem, with amount: FoodValue) async -> (FoodItem, Day?)? {
        await DataManager.shared.update(foodItem, with: amount)
    }
    
    /// Deletes the passed in `FoodItem` and returns the updated `Day` (so that this may passed on in a notification for UI updates)
    static func delete(_ foodItem: FoodItem) async -> Day? {
        await DataManager.shared.deleteFoodItem(foodItem)
    }
    
    /// Gets previously used amounts for the provided food (for quick amount buttons)
    static func usedAmounts(for food: Food) async -> [FoodValue] {
        await DataManager.shared.usedAmounts(for: food)
    }
}

/// FoodItem Helpers, when we have a context available
extension FoodItemsStore {
    static func latestFoodItemEntity(foodID: UUID, context: NSManagedObjectContext) -> FoodItemEntity? {
        FoodItemEntity.objects(
            for: NSPredicate(format: "foodEntity.id == %@", foodID.uuidString),
            sortDescriptors: [NSSortDescriptor(keyPath: \FoodItemEntity.updatedAt, ascending: false)],
            fetchLimit: 1,
            in: context
        ).first
    }
}

extension DataManager {
    
    func createFoodItem(_ food: Food, meal: Meal, amount: FoodValue) async -> (FoodItem, Day)? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.createFoodItem(food, meal, amount) { tuple in
                        guard let tuple,
                              let foodItem = FoodItem(tuple.0)
                        else {
                            continuation.resume(returning: nil)
                            return
                        }
                        let day = Day(tuple.1)
                        continuation.resume(returning: (foodItem, day))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error creating food item: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    
    func update(_ foodItem: FoodItem, with amount: FoodValue) async -> (FoodItem, Day?)? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.update(foodItem, with: amount) { tuple in
                        guard let tuple,
                              let foodItem = FoodItem(tuple.0)
                        else {
                            continuation.resume(returning: nil)
                            return
                        }
                        let day: Day?
                        if let dayEntity = tuple.1 {
                            day = Day(dayEntity)
                        } else {
                            day = nil
                        }
                        continuation.resume(returning: (foodItem, day))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error updating food item: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    
    func deleteFoodItem(_ foodItem: FoodItem) async -> Day? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.deleteFoodItem(foodItem) { dayEntity in
                        guard let dayEntity else {
                            continuation.resume(returning: nil)
                            return
                        }
                        let day = Day(dayEntity)
//                        SoundPlayer.play(.calcbotClear)
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
    
    func usedAmounts(for food: Food) async -> [FoodValue] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.usedAmounts(for: food) { amounts in
                        continuation.resume(returning: amounts)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error fetching used amounts for food: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
}

extension CoreDataManager {
    
    func usedAmounts(
        for food: Food,
        completion: @escaping (([FoodValue]) -> ())
    ) throws {
        Task {
            let bgContext = newBackgroundContext()
            await bgContext.perform {
                do {
                    
                    let amounts = FoodItemEntity.objects(
                        for: NSPredicate(format: "foodEntity.id == %@", food.id.uuidString),
                        sortDescriptors: [NSSortDescriptor(keyPath: \FoodItemEntity.updatedAt, ascending: false)],
                        in: bgContext
                    )
                    .map { $0.amount }
                    .removingDuplicates()
                    
                    let observer = NotificationCenter.default.addObserver(
                        forName: .NSManagedObjectContextDidSave,
                        object: bgContext,
                        queue: .main
                    ) { (notification) in
                        self.viewContext.mergeChanges(fromContextDidSave: notification)
                        completion(amounts)
                    }
                    
                    try bgContext.performAndWait {
                        try bgContext.save()
                    }
                    NotificationCenter.default.removeObserver(observer)

                } catch {
                    logger.error("Error: \(error.localizedDescription, privacy: .public)")
                    completion([])
                }
            }
        }
    }
}

extension CoreDataManager {
    
    
    //    func updateFoodItem(
    //        _ food: Food,
    //        _ meal: Meal,
    //        _ amount: FoodValue,
    //        _ context: NSManagedObjectContext
    //    ) throws -> (updatedFoodItemEntity: FoodItemEntity, updatedDayEntity: DayEntity) {
    //    }
    //    
    //    func deleteFoodItem(
    //    ) throws -> (deletedFoodItemID: UUID, updatedDayEntity: DayEntity) {
    //    }
    
    func deleteFoodItem(
        _ foodItem: FoodItem,
        _ context: NSManagedObjectContext
    ) throws -> DayEntity {
        guard let foodItemEntity = FoodItemEntity.object(with: foodItem.id, in: context),
              let mealEntity = foodItemEntity.mealEntity,
              let foodEntity = foodItemEntity.foodEntity
        else {
            fatalError()
        }
        
        context.delete(foodItemEntity)
        
        /// Save the context and refetch the meal entity to get the updated one
        try context.save()
        
        /// Update Food's last used data (in case it was the deleting food item)
    
        if let lastFoodItem = FoodItemsStore.latestFoodItemEntity(foodID: foodEntity.id!, context: context) {
            foodEntity.lastAmount = lastFoodItem.amount
            foodEntity.lastUsedAt = lastFoodItem.updatedAt
        } else {
            foodEntity.lastAmount = nil
            foodEntity.lastUsedAt = nil
        }

        guard let updatedMealEntity = MealEntity.object(with: mealEntity.id!, in: context) else {
            fatalError()
        }
        
        /// This cascades updates to the meal, it's parent day, and all sibiling meals
        updatedMealEntity.postFoodItemUpdate(.delete)
        
        guard let updatedDayEntity = updatedMealEntity.dayEntity else {
            fatalError()
        }
        
        return updatedDayEntity
    }
    
    func deleteFoodItem(
        _ foodItem: FoodItem,
        completion: @escaping ((DayEntity?) -> ())
    ) throws {
        Task {
            let bgContext = newBackgroundContext()
            await bgContext.perform {
                do {
                    
                    let dayEntity = try self.deleteFoodItem(foodItem, bgContext)
                    
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
}

extension CoreDataManager {
    
    func createFoodItem(
        _ food: Food,
        _ meal: Meal,
        _ amount: FoodValue,
        _ context: NSManagedObjectContext
    ) throws -> (FoodItemEntity, DayEntity) {

        guard let foodEntity = FoodEntity.object(with: food.id, in: context),
              let mealEntity = MealEntity.object(with: meal.id, in: context),
              let dayEntity = mealEntity.dayEntity
        else {
            fatalError()
        }

        let date = Date.now
        
        let entity = FoodItemEntity(context: context)
        entity.id = UUID()
        entity.amount = amount
        entity.eatenAt = nil
        entity.updatedAt = date
        entity.createdAt = date
        
        /// Before attaching, get the `mealEntity` to clean up its sort positions
        mealEntity.assertSortPositions()
        entity.sortPosition = mealEntity.nextSortPosition
        
        /// Now attach the food and meal entities
        entity.foodEntity = foodEntity
        entity.mealEntity = mealEntity

        /// Set the energy unit (this is arbitrary as we can always display it in the unit we want)
        let energyUnit: EnergyUnit = .kcal
        entity.energyUnit = energyUnit
        
        /// Compute the nutrients
        let energy = food.calculateEnergy(in: energyUnit, for: amount)
        entity.energy = energy
        entity.carb = food.calculateMacro(.carb, for: amount)
        entity.fat = food.calculateMacro(.fat, for: amount)
        entity.protein = food.calculateMacro(.protein, for: amount)

        /// Compute the relativeEnergy for all
        mealEntity.postFoodItemUpdate(.create)
        
        /// Update Food's last used data
        foodEntity.lastAmount = amount
        foodEntity.lastUsedAt = date
        
        return (entity, dayEntity)
    }
    
    func createFoodItem(
        _ food: Food,
        _ meal: Meal,
        _ amount: FoodValue,
        completion: @escaping (((FoodItemEntity, DayEntity)?) -> ())
    ) throws {
        Task {
            let bgContext = newBackgroundContext()
            await bgContext.perform {
                do {
                    
                    let (foodItemEntity, dayEntity) = try self.createFoodItem(food, meal, amount, bgContext)
                    bgContext.insert(foodItemEntity)
                    
                    let observer = NotificationCenter.default.addObserver(
                        forName: .NSManagedObjectContextDidSave,
                        object: bgContext,
                        queue: .main
                    ) { (notification) in
                        self.viewContext.mergeChanges(fromContextDidSave: notification)
                        completion((foodItemEntity, dayEntity))
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

extension CoreDataManager {
    
    func update(
        _ foodItem: FoodItem,
        with amount: FoodValue,
        context: NSManagedObjectContext
    ) throws -> (FoodItemEntity, DayEntity?) {

        guard
            let entity = FoodItemEntity.object(with: foodItem.id, in: context),
            let foodEntity = FoodEntity.object(with: foodItem.food.id, in: context)
        else {
            fatalError()
        }

        let date = Date.now
        
        entity.amount = amount
        entity.updatedAt = date
        
        /// Set the energy unit (this is arbitrary as we can always display it in the unit we want)
        let energyUnit: EnergyUnit = .kcal
        entity.energyUnit = energyUnit
        
        /// Compute the nutrients
        let food = foodItem.food
        let energy = food.calculateEnergy(in: energyUnit, for: amount)
        entity.energy = energy
        entity.carb = food.calculateMacro(.carb, for: amount)
        entity.fat = food.calculateMacro(.fat, for: amount)
        entity.protein = food.calculateMacro(.protein, for: amount)

        /// Update Food's last used data
        foodEntity.lastAmount = amount
        foodEntity.lastUsedAt = date
 
        /// Save before fetching relationships again
        try context.save()
        
        /// If there's an attached meal, update the stats in it and the day entity
        if let mealID = foodItem.mealID,
           let mealEntity = MealEntity.object(with: mealID, in: context),
           let dayEntity = mealEntity.dayEntity
        {
            /// Compute the relativeEnergy for all
            mealEntity.postFoodItemUpdate(.create)
            
            //TODO: Make sure we're updating the day entity properly here
            return (entity, dayEntity)
        }

        return (entity, nil)
    }
    
    func update(
        _ foodItem: FoodItem,
        with amount: FoodValue,
        completion: @escaping (((FoodItemEntity, DayEntity?)?) -> ())
    ) throws {
        Task {
            let bgContext = newBackgroundContext()
            await bgContext.perform {
                do {
                    
                    let (foodItemEntity, dayEntity) = try self.update(
                        foodItem, with: amount, context: bgContext
                    )
                    bgContext.insert(foodItemEntity)
                    
                    let observer = NotificationCenter.default.addObserver(
                        forName: .NSManagedObjectContextDidSave,
                        object: bgContext,
                        queue: .main
                    ) { (notification) in
                        self.viewContext.mergeChanges(fromContextDidSave: notification)
                        completion((foodItemEntity, dayEntity))
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
import FoodDataTypes

extension DayEntity {
    
    /// Calculates badge width for a Meal.
    func calculateRelativeEnergy(energy: Double, _ energyUnit: EnergyUnit) -> Double {
        let kcal = energyUnit.convert(energy, to: .kcal)
        let values = energyValuesOfMeals(in: .kcal)
        return kcal.relativeScale(in: values)
    }
    
    func energyValuesOfMeals(in unit: EnergyUnit) -> [Double] {
        mealEntitiesArray
            .filter { !$0.foodItemEntitiesArray.isEmpty }
            .map { $0.energy(in: .kcal) }
    }

}

extension MealEntity {
    
    func assertSortPositions() {
        let sorted = foodItemEntitiesArray.sorted(by: { $0.sortPosition < $1.sortPosition })
        /// We're sorting the food item entities by their sort positions and asserting that they are as expected
        for i in sorted.indices {
            sorted[i].sortPosition = Int16(i)
        }
    }

    var nextSortPosition: Int16 {
        let sorted = foodItemEntitiesArray.sorted(by: { $0.sortPosition < $1.sortPosition })
        guard let first = sorted.last else { return 1 }
        return first.sortPosition + 1
    }
}

enum ModifyAction {
    case create
    case delete
    case update
}

extension DayEntity {
    func postFoodItemUpdate(_ action: ModifyAction) {
        
        /// First update the relative energies
        for mealEntity in mealEntitiesArray {
            
            /// Of all Food Items
            for foodItemEntity in mealEntity.foodItemEntitiesArray {
                foodItemEntity.relativeEnergy = mealEntity.calculateRelativeEnergy(energy: foodItemEntity.energy, energyUnit)
            }

            /// And Meals
            mealEntity.relativeEnergy = mealEntity.calculatedRelativeEnergy
        }
        
        /// Now update the stats of the `Day` itself
        let day = Day(self)
        
        let previousHasMetAllGoals = day.hasMetAllGoals
        let previousHasGoalsInExcess = day.hasGoalsInExcess
        
        energy = day.calculateEnergy(in: energyUnit)
        carb = day.calculateMacro(.carb)
        fat = day.calculateMacro(.fat)
        protein = day.calculateMacro(.protein)
        micros = day.calculatedMicros
        
        let updatedDay = Day(self)
        let sound: SoundPlayer.Sound
        if !previousHasGoalsInExcess && updatedDay.hasGoalsInExcess {
            sound = .chiptunesError
        } else if !previousHasMetAllGoals && updatedDay.hasMetAllGoals {
            sound = .chiptunesSuccessLong
        } else {
            switch action {
            case .create:   sound = .clearSwoosh
            case .delete:   sound = .letterpressDelete
            case .update:   sound = .clearSwoosh
            }
        }
        SoundPlayer.play(sound)
    }
}

extension MealEntity {
    
    func postFoodItemUpdate(_ action: ModifyAction) {
        updateNutrients()
        dayEntity?.postFoodItemUpdate(action)
    }
    
    /// Recalculates its own badge width. Use this after inserting, deleting or updating a food item (or a meal of the same day).
    func updateNutrients() {
        /// First re-calculate the energy and macro values
        energy = calculateEnergy(in: energyUnit)
        carb = calculateMacro(.carb)
        fat = calculateMacro(.fat)
        protein = calculateMacro(.protein)
    }
    
    func calculateEnergy(in unit: EnergyUnit) -> Double {
        foodItems.reduce(0) {
            $0 + $1.calculateEnergy(in: unit)
        }
    }
    
    func calculateMacro(_ macro: Macro) -> Double {
        foodItems.reduce(0) {
            $0 + $1.calculateMacro(macro)
        }
    }

    var calculatedRelativeEnergy: Double {
        dayEntity?.calculateRelativeEnergy(energy: energy, energyUnit) ?? 0
    }

    func energy(in unit: EnergyUnit) -> Double {
        self.energyUnit.convert(energy, to: unit)
    }

    func calculateRelativeEnergy(energy: Double, _ energyUnit: EnergyUnit) -> Double {
        guard let dayEntity else { return 0 }
        let kcal = energyUnit.convert(energy, to: .kcal)
        let values = dayEntity.energyValuesOfFoodItems(in: .kcal)
        return kcal.relativeScale(in: values)
    }
}

extension FoodItemEntity {
    func energy(in unit: EnergyUnit) -> Double {
        self.energyUnit.convert(energy, to: unit)
    }
    
    var calculatedRelativeEnergy: Double {
        mealEntity?.calculateRelativeEnergy(energy: energy, energyUnit) ?? 0
    }
}
extension DayEntity {
    func energyValuesOfFoodItems(in unit: EnergyUnit) -> [Double] {
        foodItemEntities.map { $0.energy(in: .kcal) }
    }
    
    var foodItemEntities: [FoodItemEntity] {
        var entities: [FoodItemEntity] = []
        for mealEntity in mealEntitiesArray {
            entities.append(contentsOf: mealEntity.foodItemEntitiesArray)
        }
        return entities
    }

}
