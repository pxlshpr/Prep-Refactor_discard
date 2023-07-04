import Foundation

struct Day: Codable, Hashable {
    
    let dateString: String
    
    var energy: Double
    var energyUnit: EnergyUnit
    var carb: Double
    var fat: Double
    var protein: Double
    var micros: [FoodNutrient]
    
    var meals: [Meal]
    
    init(
        dateString: String,
        energy: Double = 0,
        energyUnit: EnergyUnit = .kcal,
        carb: Double = 0,
        fat: Double = 0,
        protein: Double = 0,
        micros: [FoodNutrient] = [],
        meals: [Meal]
    ) {
        self.dateString = dateString
        self.energy = energy
        self.energyUnit = energyUnit
        self.carb = carb
        self.fat = fat
        self.protein = protein
        self.micros = micros
        self.meals = meals
    }
    
    init(_ entity: DayEntity) {
        self.init(
            dateString: entity.dateString!,
            meals: entity.meals
        )
    }
}

extension Day: Identifiable {
    var id: String {
        dateString
    }
}

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

extension Day {

    func meal(with id: UUID) -> Meal? {
        meals.first(where: { $0.id == id })
    }

    func contains(meal: Meal) -> Bool {
        meals.contains(where: { $0.id == meal.id })
    }
}

import FoodDataTypes

extension Day {
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
        meals.reduce(0) { $0 + $1.calculateEnergy(in: unit) }
    }
    
    func calculateMacro(_ macro: Macro) -> Double {
        meals.reduce(0) { $0 + $1.calculateMacro(macro) }
    }
    
    var calculatedMicros: [FoodNutrient] {
        presentMicros
            .map { micro in
                let unit = micro.defaultUnit
                let value = calculateMicro(micro, in: unit)
                return FoodNutrient(micro: micro, value: value, unit: unit)
            }
    }
    
    var presentMicros: [Micro] {
        Micro.allCases
            .filter { micro in
                meals.contains(where: { meal in
                    meal.foodItems.contains(where: { foodItem in
                        foodItem.food.micros.contains(where: { foodNutrient in
                            foodNutrient.micro == micro
                        })
                    })
                })
            }
    }
    
    func calculateMicro(_ micro: Micro, in unit: NutrientUnit? = nil) -> Double {
        let unit = unit ?? micro.defaultUnit
        return meals.reduce(0) { $0 + $1.calculateMicro(micro, in: unit) }
    }
}
