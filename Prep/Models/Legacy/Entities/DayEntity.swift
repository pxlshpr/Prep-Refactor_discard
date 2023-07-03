import Foundation
import SwiftData

@Model
class DayEntity {
    var uuid: String
    var calendarDayString: String
    
//    @Relationship
//    var mealEntities: [MealEntity]?
    
//    var diet: GoalSet?
//    var biometrics: Biometrics?
    
//    var markedAsFasted: Bool
    
    init(
        uuid: String = UUID().uuidString,
        calendarDayString: String
//        mealEntities: [MealEntity] = []
    ) {
        self.uuid = uuid
        self.calendarDayString = calendarDayString
//        self.mealEntities = mealEntities
    }
}

extension DayEntity {
    var date: Date {
        Date(fromCalendarDayString: calendarDayString)!
    }
}
