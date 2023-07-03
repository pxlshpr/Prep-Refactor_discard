import Foundation
import CoreData

extension DayEntity2: Entity {
    
    convenience init(context: NSManagedObjectContext, dateString: String) {
        self.init(context: context)
        self.dateString = dateString
    }
    
    convenience init(context: NSManagedObjectContext, day: Day2) {
        self.init(context: context)
        self.dateString = day.dateString
    }
    
    convenience init(_ context: NSManagedObjectContext, _ legacy: LegacyDay) {
        self.init(context: context)
        self.dateString = legacy.calendarDayString
    }
}

extension DayEntity2 {
    var mealEntitiesArray: [MealEntity2] {
        mealEntities?.allObjects as? [MealEntity2] ?? []
    }
    var meals: [Meal2] {
        mealEntitiesArray
            .map { Meal2($0) }
            .sorted()
    }
}
