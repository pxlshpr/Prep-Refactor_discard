import Foundation
import CoreData

extension MealEntity2 {
    
    convenience init(context: NSManagedObjectContext, meal: Meal2) {
        self.init(context: context)
        self.id = meal.id
        self.name = meal.name
        self.time = meal.time
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
