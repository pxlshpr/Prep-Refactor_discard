import Foundation
import CoreData

import FoodDataTypes

extension FoodItemEntity: Entity {
    
    func fill(_ legacy: LegacyFoodItem) {
        self.id = UUID(uuidString: legacy.id)
        self.amount = legacy.amount.foodValue
        
//        if let badgeWidth = legacy.badgeWidth {
//            self.badgeWidth = badgeWidth
//        } else {
//            self.badgeWidth = 0
//        }
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
        
        /// Manually calculating totals
        guard let foodItem = FoodItem(self) else {
            fatalError()
        }
        self.energy = foodItem.calculateEnergy(in: foodEntity.energyUnit)
        self.energyUnit = foodEntity.energyUnit
        self.carb = foodItem.calculateMacro(.carb)
        self.fat = foodItem.calculateMacro(.fat)
        self.protein = foodItem.calculateMacro(.protein)
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
