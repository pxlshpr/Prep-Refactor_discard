import Foundation
import Observation

@Observable class MealModel {
    
    var date: Date = Date.now
    var meal: Meal? = nil
    var mealTimes: [Date] = []
    var name: String = ""
    var time: Date = Date.now
    
    init(
        date: Date,
        meal: Meal?,
        mealTimes: [Date],
        name: String,
        time: Date
    ) {
        self.date = date
        self.meal = meal
        self.mealTimes = mealTimes
        self.name = name
        self.time = time
    }
    
    init() { }

    func reset() {
        self.reset(meal: nil, date: nil, day: nil)
    }
    func reset(date: Date) {
        self.reset(meal: nil, date: date, day: nil)
    }
    func reset(meal: Meal, day: Day) {
        self.reset(meal: meal, date: nil, day: day)
    }
    
    private func reset(
        meal: Meal?,
        date: Date?,
        day: Day?
    ) {
        let date = meal?.time ?? date ?? Date.now
        self.date = date
        
        self.mealTimes = day?.mealTimes ?? []
        
        self.meal = meal
        
        if let meal {
            name = meal.name
            time = meal.time
        } else {
            name = Meal.defaultName(at: date)
            time = date
        }
    }
}
