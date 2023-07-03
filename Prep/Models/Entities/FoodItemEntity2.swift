import Foundation
import CoreData

import FoodDataTypes

extension FoodItemEntity2 {
    
    convenience init(
        context: NSManagedObjectContext,
        foodItem: FoodItem2,
        foodEntity: FoodEntity2,
        mealEntity: MealEntity2? = nil
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
}

extension FoodItemEntity2 {

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
