import Foundation

struct Meal: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var time: Date
    var date: Date
    
    var energy: Double
    var energyUnit: EnergyUnit
    var carb: Double
    var fat: Double
    var protein: Double
    
    var largestEnergyInKcal: Double

    var foodItems: [FoodItem]
    
    init(
        id: UUID,
        name: String,
        time: Date,
        date: Date,
        energy: Double,
        energyUnit: EnergyUnit,
        carb: Double,
        fat: Double,
        protein: Double,
        largestEnergyInKcal: Double,
        foodItems: [FoodItem]
    ) {
        self.id = id
        self.name = name
        self.time = time
        self.date = date
        self.energy = energy
        self.energyUnit = energyUnit
        self.carb = carb
        self.fat = fat
        self.protein = protein
        self.largestEnergyInKcal = largestEnergyInKcal
        self.foodItems = foodItems
    }
    
    init(_ entity: MealEntity) {
        self.init(
            id: entity.id!,
            name: entity.name!,
            time: entity.time,
            date: Date(fromCalendarDayString: entity.dayEntity!.dateString!)!,
            energy: entity.energy,
            energyUnit: entity.energyUnit,
            carb: entity.carb,
            fat: entity.fat,
            protein: entity.protein,
            largestEnergyInKcal: entity.largestEnergyInKcal,
            foodItems: entity.foodItems
        )
    }
}

extension Meal {
    
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
            MacroValue(macro: .carb, value: carb),
            MacroValue(macro: .fat, value: fat),
            MacroValue(macro: .protein, value: protein)
        ]
    }
    
    func energy(in unit: EnergyUnit) -> Double {
        switch unit {
        case .kJ:
            switch energyUnit {
            case .kJ:   energy
            case .kcal: energy / KjPerKcal
            }
        case .kcal:
            switch energyUnit {
            case .kcal: energy
            case .kJ:   energy * KjPerKcal
            }
        }
    }
    
    func calculateEnergy(in unit: EnergyUnit) -> Double {
        foodItems.reduce(0) {
            $0 + $1.calculateEnergy(in: unit)
        }
    }
    
    func calculateMacro(_ macro: Macro) -> Double {
        foodItems.reduce(0) {
            $0 + $1.calculateMacro(macro)
        }
    }
    
    func calculateMicro(_ micro: Micro, in unit: NutrientUnit) -> Double {
        foodItems.reduce(0) {
            $0 + $1.calculateMicro(micro, in: unit)
        }
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

    static func defaultTime(for date: Date) -> Date {
        date.isToday
        ? Date.now
        : date.setting(hour: 12)
    }
}

extension Meal {
    var itemsCountDescription: String {
        "\(foodItems.count) \(foodItems.count == 1 ? "entry" : "entries")"
    }
}
