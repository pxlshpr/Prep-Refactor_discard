import Foundation
import CoreData

import FoodDataTypes

extension FoodItemEntity: Entity {
    
    convenience init(
        context: NSManagedObjectContext,
        foodItem: FoodItem,
        foodEntity: FoodEntity,
        mealEntity: MealEntity? = nil
    ) {
        self.init(context: context)
        self.id = foodItem.id
        self.amount = foodItem.amount
        
        self.foodEntity = foodEntity
        self.mealEntity = mealEntity
        
        self.badgeWidth = foodItem.badgeWidth
        self.sortPosition = Int16(foodItem.sortPosition)

        self.eatenAt = foodItem.eatenAt
        self.updatedAt = foodItem.updatedAt
        self.createdAt = foodItem.createdAt
    }
    
    func fill(_ legacy: LegacyFoodItem) {
        self.id = UUID(uuidString: legacy.id)
        self.amount = legacy.amount.foodValue
        
        if let badgeWidth = legacy.badgeWidth {
            self.badgeWidth = badgeWidth
        } else {
            self.badgeWidth = 0
        }
        self.sortPosition = Int16(legacy.sortPosition)
        
        if let markedAsEatenAt = legacy.markedAsEatenAt {
            self.eatenAt = Date(timeIntervalSince1970: markedAsEatenAt)
        }
        self.updatedAt = Date(timeIntervalSince1970: legacy.updatedAt)
        self.createdAt = Date(timeIntervalSince1970: legacy.updatedAt)
    }
    
    convenience init(
        _ context: NSManagedObjectContext,
        _ legacy: LegacyFoodItem,
        _ foodEntity: FoodEntity,
        _ mealEntity: MealEntity? = nil
    ) {
        self.init(context: context)
        self.fill(legacy)
        
        self.foodEntity = foodEntity
        self.mealEntity = mealEntity
    }
}

extension FoodItemEntity {
    var food: Food {
        Food(foodEntity!)
    }
    
    var mealID: UUID? {
        mealEntity?.id
    }
}

extension FoodItemEntity {

    var energyUnit: EnergyUnit {
        get {
            EnergyUnit(rawValue: Int(energyUnitValue)) ?? .kcal
        }
        set {
            energyUnitValue = Int16(newValue.rawValue)
        }
    }

    var amount: FoodValue {
        get {
            guard let amountData else {
                fatalError()
            }
            return try! JSONDecoder().decode(FoodValue.self, from: amountData)
        }
        set {
            self.amountData = try! JSONEncoder().encode(newValue)
        }
    }
}
