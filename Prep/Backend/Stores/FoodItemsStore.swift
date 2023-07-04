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
        /// Steps
        /// [x] Fetch `FoodEntity`
        /// [x] Fetch `MealEntity`
        /// [x] Create the `FoodItemEntity`
        /// [x] Compute and fill in the nutrients
        ///     [x] Energy, EnergyUnit
        ///     [x] Carb, Fat, Protein
        /// [x] Compute and fill in the badge width
        ///     [x] Get all the meals of the day
        ///     [x] Use the total energy for the day to determine the badgeWidth
        /// [x] Compute and fill in the sortPosition
        ///     [x] Get the last sort position for the meal
        ///     [x] Increment it by 1
        ///     [x] While we're here, ensure that sortPositions are valid

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
        let energy = food.scaledEnergyValue(energyUnit, amount)
        entity.energy = energy
        entity.carb = food.scaledMacroValue(.carb, amount)
        entity.fat = food.scaledMacroValue(.fat, amount)
        entity.protein = food.scaledMacroValue(.protein, amount)

        /// Compute the badge width
        entity.badgeWidth = mealEntity.calculateBadgeWidth(energy: energy, energyUnit: energyUnit)
        
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
                    completion(entity)
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
    func calculateBadgeWidth(energy: Double, _ energyUnit: EnergyUnit) -> Double {
        Prep.calculateBadgeWidth(
            for: energyUnit.convert(energy, to: .kcal),
            within: energyValuesOfMeals(in: .kcal)
        )
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
        badgeWidth = calculatedBadgeWidth
    }
    
    func calculateEnergy(in unit: EnergyUnit) -> Double {
        foodItems.reduce(0) {
            $0 + $1.scaledEnergyValue(in: unit)
        }
    }
    
    func total(for macro: Macro) -> Double {
        foodItems.reduce(0) {
            $0 + $1.scaledMacroValue(for: macro)
        }
    }

    var calculatedBadgeWidth: CGFloat {
        dayEntity?.calculateBadgeWidth(energy: energy, energyUnit) ?? 0
    }

    func energy(in unit: EnergyUnit) -> Double {
        self.energyUnit.convert(energy, to: unit)
    }

    /// Calculates badge width for a FoodItem.
    func calculateBadgeWidth(energy: Double, energyUnit: EnergyUnit) -> Double {
        guard let dayEntity else { return 0 }
        return Prep.calculateBadgeWidth(
            for: energyUnit.convert(energy, to: .kcal),
            within: dayEntity.energyValuesOfFoodItems(in: .kcal)
        )
    }
}

extension FoodItemEntity {
    func energy(in unit: EnergyUnit) -> Double {
        self.energyUnit.convert(energy, to: unit)
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
