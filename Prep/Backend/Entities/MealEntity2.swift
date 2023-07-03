import Foundation
import CoreData

extension MealEntity2: Entity {
    
    convenience init(context: NSManagedObjectContext, meal: Meal2) {
        self.init(context: context)
        self.id = meal.id
        self.name = meal.name
        self.time = meal.time
    }
    
    convenience init(_ context: NSManagedObjectContext, _ legacy: LegacyMeal, _ dayEntity: DayEntity2) {
        self.init(context: context)
        self.id = UUID(uuidString: legacy.id)!
        self.name = legacy.name
        self.time = Date(timeIntervalSince1970: legacy.time)
        self.dayEntity = dayEntity
    }
}

extension MealEntity2 {
    var foodItemEntitiesArray: [FoodItemEntity2] {
        foodItemEntities?.allObjects as? [FoodItemEntity2] ?? []
    }
    var foodItems: [FoodItem2] {
        foodItemEntitiesArray.compactMap { FoodItem2($0) }
    }
}

extension MealEntity2 {
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
}
