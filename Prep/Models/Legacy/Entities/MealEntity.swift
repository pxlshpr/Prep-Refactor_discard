import Foundation
import SwiftData

@Model
final class MealEntity {
    
    ///**Warning**: Don't name this `id` or we get a crash when deleting on the main context.
    var uuid: String
    
    var name: String
    var time: Double
    
//    var markedAsEatenAt: Double?
//    var badgeWidth: Double?
//    var mealType: GoalSet?

    var dayID: String?
    
//    @Relationship(inverse: \DayEntity.mealEntities)
//    var dayEntity: DayEntity?
//    
//    @Relationship(.cascade, inverse: \FoodItemEntity.mealEntity)
//    var foodItemEntities: [FoodItemEntity]?
    

    init(
        uuid: String = UUID().uuidString,
        dayEntity: DayEntity? = nil,
        name: String,
        time: Double
    ) {
        self.uuid = uuid
        self.dayID = dayEntity?.uuid
        self.name = name
        self.time = time
    }    
}

extension MealEntity {
    var timeDate: Date {
        Date(timeIntervalSince1970: time)
    }
    
    var timeString: String {
        Date(timeIntervalSince1970: time).formatted(date: .omitted, time: .shortened).lowercased()
    }
}
