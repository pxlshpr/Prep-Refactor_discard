import Foundation

struct Meal: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var time: Date
    var date: Date
    var foodItems: [FoodItem]
    
    init(
        id: UUID,
        name: String,
        time: Date,
        date: Date,
        foodItems: [FoodItem]
    ) {
        self.id = id
        self.name = name
        self.time = time
        self.date = date
        self.foodItems = foodItems
    }
    
    init(_ entity: MealEntity) {
        self.init(
            id: entity.id!,
            name: entity.name!,
            time: entity.time,
            date: Date(fromCalendarDayString: entity.dayEntity!.dateString!)!,
            foodItems: entity.foodItems
        )
    }
}

import FoodDataTypes

extension Meal: Comparable {

    static func <(lhs: Meal, rhs: Meal) -> Bool {
        return lhs.time < rhs.time
    }
}
