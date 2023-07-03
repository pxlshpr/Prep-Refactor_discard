import Foundation

//struct Day {
//    
//    var id: String = UUID().uuidString
//    var date: Date = Date.now
//    var meals: [Meal] = []
//    
//    init() { }
//}

extension Day {
    var mealTimes: [Date] {
        meals.map { $0.time }
    }
    
    var sortedMeals: [Meal] {
        meals.sorted(by: { $0.time < $1.time })
    }
    
    var date: Date {
        Date(fromCalendarDayString: dateString)!
    }
}
