import Foundation
import CoreData

extension DayEntity: Entity {
    
    convenience init(context: NSManagedObjectContext, dateString: String) {
        self.init(context: context)
        self.dateString = dateString
    }
    
    convenience init(context: NSManagedObjectContext, day: Day) {
        self.init(context: context)
        self.dateString = day.dateString
    }
    
    convenience init(_ context: NSManagedObjectContext, _ legacy: LegacyDay) {
        self.init(context: context)
        self.dateString = legacy.calendarDayString
    }
}

extension DayEntity {
    var mealEntitiesArray: [MealEntity] {
        mealEntities?.allObjects as? [MealEntity] ?? []
    }
    var meals: [Meal] {
        mealEntitiesArray
            .map { Meal($0) }
            .sorted()
    }
}
