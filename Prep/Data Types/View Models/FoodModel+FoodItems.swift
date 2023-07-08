import Foundation

import FoodDataTypes

extension FoodModel {
    var title: String {
        let prefix = isEditing ? "Edit" : "New"
        return "\(prefix) \(foodType.name)"
    }
    
    var foodItemsName: String {
        foodType == .recipe ? "Ingredients" : "Foods"
    }
    var foodItemsSingularName: String {
        foodType == .recipe ? "Ingredients" : "Foods"
    }

    var foodItemsCountString: String {
        foodItems.count == 0 ? "" : "\(foodItems.count)"
    }

    var lastFoodItemsSortPosition: Int {
        foodItems
            .sorted(by: { $0.sortPosition < $1.sortPosition })
            .last?.sortPosition ?? 1
    }
    
    func calculatedFoodItemsTotal(for macro: Macro) -> Double {
        foodItems.reduce(0) { partialResult, foodItem in
            partialResult + foodItem.value(for: macro)
        }
    }

    func calculatedFoodItemsTotalForEnergy(in unit: EnergyUnit) -> Double {
        foodItems.reduce(0) { partialResult, foodItem in
            partialResult + foodItem.valueForEnergy(in: unit)
        }
    }

    func calculatedFoodItemsTotal(for nutrient: Nutrient) -> Double {
        switch nutrient {
        case .energy:           calculatedFoodItemsTotalForEnergy(in: .kcal)
        case .macro(let macro): calculatedFoodItemsTotal(for: macro)
        case .micro(let micro): calculatedFoodItemsTotal(for: micro)
        }
    }
    
    func calculatedFoodItemsTotal(for micro: Micro) -> Double {
        foodItems.reduce(0) { partialResult, foodItem in
            partialResult + foodItem.value(for: micro, in: micro.defaultUnit)
        }
    }

    func calculateNutrients() {
        self.energy.value = calculatedFoodItemsTotalForEnergy(in: .kcal)
        self.carb.value = calculatedFoodItemsTotal(for: .carb)
        self.fat.value = calculatedFoodItemsTotal(for: .fat)
        self.protein.value = calculatedFoodItemsTotal(for: .protein)
    }
    
    var primaryFoodItemsMacro: Macro {
        let carbCalories = carb.value * KcalsPerGramOfCarb
        let fatCalories = fat.value * KcalsPerGramOfFat
        let proteinCalories = protein.value * KcalsPerGramOfProtein
        if carbCalories > fatCalories && carbCalories > proteinCalories {
            return .carb
        }
        if fatCalories > carbCalories && fatCalories > proteinCalories {
            return .fat
        }
        return .protein
    }
    
    func value(for macro: Macro) -> Double {
        switch macro {
        case .carb:     carb.value
        case .fat:      fat.value
        case .protein:  protein.value
        }
    }
    func value(for micro: Micro) -> Double {
        0
    }
    
    func value(for nutrient: Nutrient) -> Double {
        switch nutrient {
        case .energy:           energy.value
        case .macro(let macro): value(for: macro)
        case .micro(let micro): value(for: micro)
        }
    }
}

//MARK: - FoodItem

extension FoodItem {
    func value(for macro: Macro) -> Double {
        switch macro {
        case .carb: carb
        case .protein: protein
        case .fat: fat
        }
    }

    func valueForEnergy(in unit: EnergyUnit) -> Double {
        energyUnit.convert(energy, to: unit)
    }

    func value(for micro: Micro, in unit: NutrientUnit) -> Double {
        food.value(for: .micro(micro), with: amount)
    }
}

//MARK: Array+FoodItem

extension Array where Element == FoodItem {
    var largestEnergyInKcal: Double {
        self
            .map { $0.energyUnit.convert($0.energy, to: .kcal) }
            .sorted()
            .last ?? 0
    }
    
    mutating func setLargestEnergy() {
        let largest = largestEnergyInKcal
        for i in indices {
            self[i].largestEnergyInKcal = largest
        }
    }
}
