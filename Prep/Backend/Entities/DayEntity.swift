import Foundation
import CoreData

import FoodDataTypes

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
    
    var energyUnit: EnergyUnit {
        get {
            EnergyUnit(rawValue: Int(energyUnitValue)) ?? .kcal
        }
        set {
            energyUnitValue = Int16(newValue.rawValue)
        }
    }

    var micros: [FoodNutrient] {
        get {
            guard let microsData else { fatalError() }
            return try! JSONDecoder().decode([FoodNutrient].self, from: microsData)
        }
        set {
            self.microsData = try! JSONEncoder().encode(newValue)
        }
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
