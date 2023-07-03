import Foundation

struct Meal: Identifiable {
    var id: String = ""
    var name: String = ""
    var time: Date = Date.now
    var date: Date = Date.now
    var foodItems: [FoodItem] = []

    init() { }
    
    init(
        _ entity: MealEntity,
        dayEntity: DayEntity,
        foodItems: [FoodItem]
    ) {
        self.init()
        self.id = entity.uuid
        self.name = entity.name
        self.time = Date(timeIntervalSince1970: entity.time)
        self.date = dayEntity.date
        self.foodItems = foodItems
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
        foodItems.reduce(0) {
            $0 + $1.scaledMacroValue(for: macro)
        }
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
