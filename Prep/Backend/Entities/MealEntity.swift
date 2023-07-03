import Foundation
import CoreData

import FoodDataTypes

extension MealEntity: Entity {
    
    convenience init(context: NSManagedObjectContext, meal: Meal) {
        self.init(context: context)
        self.id = meal.id
        self.name = meal.name
        self.time = meal.time
        
        self.energy = meal.energy
        self.energyUnit = meal.energyUnit
        self.carb = meal.carb
        self.fat = meal.fat
        self.protein = meal.protein
        self.badgeWidth = meal.badgeWidth
    }
    
    convenience init(
        _ context: NSManagedObjectContext,
        _ legacy: LegacyMeal,
        _ dayEntity: DayEntity
    ) {
        self.init(context: context)
        self.id = UUID(uuidString: legacy.id)!
        self.name = legacy.name
        self.time = Date(timeIntervalSince1970: legacy.time)
        
        self.badgeWidth = legacy.badgeWidth ?? 0
        
        self.dayEntity = dayEntity
    }
}

extension MealEntity {
    var foodItemEntitiesArray: [FoodItemEntity] {
        foodItemEntities?.allObjects as? [FoodItemEntity] ?? []
    }
    var foodItems: [FoodItem] {
        foodItemEntitiesArray.compactMap { FoodItem($0) }
    }
}

extension MealEntity {
    var time: Date {
        get {
            guard let timeString,
                  let date = Date(fromTimeString: timeString)
            else { fatalError() }
            return date
        }
        set {
            self.timeString = newValue.timeString
        }
    }
    
    var energyUnit: EnergyUnit {
        get {
            EnergyUnit(rawValue: Int(energyUnitValue)) ?? .kcal
        }
        set {
            energyUnitValue = Int16(newValue.rawValue)
        }
    }
}
