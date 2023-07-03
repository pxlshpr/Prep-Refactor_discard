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

extension Meal: Comparable {

    static func <(lhs: Meal, rhs: Meal) -> Bool {
        return lhs.time < rhs.time
    }
}

extension Meal {
    var timeString: String {
        time
            .formatted(date: .omitted, time: .shortened)
            .lowercased()
    }
}

extension Meal {
    var title: String {
        "\(name) • \(time.shortTime)"
    }
}

import FoodDataTypes

extension Meal {
    var macrosChartData: [MacroValue] {
        [
            MacroValue(macro: .carb, value: total(for: .carb)),
            MacroValue(macro: .fat, value: total(for: .fat)),
            MacroValue(macro: .protein, value: total(for: .protein))
        ]
    }
    
    func total(for macro: Macro) -> Double {
        0
//        foodItems.reduce(0) {
//            $0 + $1.scaledMacroValue(for: macro)
//        }
    }
    
    func energy(in unit: EnergyUnit) -> Double {
        586
//        foodItems.reduce(0) {
//            $0 + $1.scaledEnergyValue(in: unit)
//        }
    }
}

extension Meal {

    static func defaultName(at time: Date = Date()) -> String {
        switch time.h {
        /// Midnight
        case 0...3:
            return "Midnight Snack"
        case 4...9:
            return "Breakfast"
        case 10...11:
            return "Brunch"
        case 12...15:
            return "Lunch"
        case 16...17:
            return "Snack"
        case 18...20:
            return "Dinner"
        case 21...:
            return "Supper"
        default:
            return "Breakfast"
        }
    }

}
