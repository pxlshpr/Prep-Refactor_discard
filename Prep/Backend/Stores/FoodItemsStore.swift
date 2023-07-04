import Foundation
import CoreData
import OSLog

private let logger = Logger(subsystem: "FoodItems", category: "")

class FoodItemsStore {
    static let shared = FoodItemsStore()
    
    static func create(_ food: Food, meal: Meal, amount: FoodValue) async -> FoodItem? {
        await DataManager.shared.create(food, meal: meal, amount: amount)
    }
}

extension DataManager {
    
    func create(_ food: Food, meal: Meal, amount: FoodValue) async -> FoodItem? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.createFoodItem(food, meal, amount) { foodItemEntity in
                        guard let foodItemEntity else {
                            continuation.resume(returning: nil)
                            return
                        }
                        let foodItem = FoodItem(foodItemEntity)
                        continuation.resume(returning: foodItem)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error creating food item: error: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}

extension CoreDataManager {
    
    func createFoodItem(_ food: Food, _ meal: Meal, _ amount: FoodValue, _ context: NSManagedObjectContext) throws -> FoodItemEntity {

        guard let foodEntity = FoodEntity.object(with: food.id, in: context) else {
            fatalError()
        }
        guard let mealEntity = MealEntity.object(with: meal.id, in: context) else {
            fatalError()
        }

        let entity = FoodItemEntity(context: context)
        entity.id = UUID()
        entity.amount = amount
        entity.eatenAt = nil
        entity.updatedAt = Date.now
        entity.createdAt = Date.now
        
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

        /// Compute the relativeEnergy
        entity.relativeEnergy = mealEntity.calculateRelativeEnergy(energy: energy, energyUnit)
        
        /// Get the meal entity to update its stats (nutrients and badge width)
        mealEntity.updateStats()
        
        return entity
    }
    
    func createFoodItem(_ food: Food, _ meal: Meal, _ amount: FoodValue, completion: @escaping ((FoodItemEntity?) -> ())) throws {
        Task {
            let bgContext =  newBackgroundContext()
            await bgContext.perform {
                do {
                    
                    let entity = try self.createFoodItem(food, meal, amount, bgContext)
                    bgContext.insert(entity)
                    
                    let observer = NotificationCenter.default.addObserver(
                        forName: .NSManagedObjectContextDidSave,
                        object: bgContext,
                        queue: .main
                    ) { (notification) in
                        self.viewContext.mergeChanges(fromContextDidSave: notification)
                        completion(entity)
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

extension MealEntity {
    
    /// Recalculates its own badge width. Use this after inserting, deleting or updating a food item (or a meal of the same day).
    func updateStats() {
        /// First re-calculate the energy and macro values
        energy = calculateEnergy(in: energyUnit)
        carb = total(for: .carb)
        fat = total(for: .fat)
        protein = total(for: .protein)
        relativeEnergy = calculatedRelativeEnergy
    }
    
    func calculateEnergy(in unit: EnergyUnit) -> Double {
        foodItems.reduce(0) {
            $0 + $1.calculateEnergy(in: unit)
        }
    }
    
    func total(for macro: Macro) -> Double {
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
