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
    
    var lastFoodItemsSortPosition: Int {
        foodItems
            .sorted(by: { $0.sortPosition < $1.sortPosition })
            .last?.sortPosition ?? 1
    }
    
    func foodItemsTotal(for macro: Macro) -> Double {
        foodItems.reduce(0) { partialResult, foodItem in
            partialResult + foodItem.value(for: macro)
        }
    }
    
    func calculateNutrients() {
        self.carb.value = foodItemsTotal(for: .carb)
        self.fat.value = foodItemsTotal(for: .fat)
        self.protein.value = foodItemsTotal(for: .protein)
    }
}

extension FoodItem {
    func value(for macro: Macro) -> Double {
        switch macro {
        case .carb: carb
        case .protein: protein
        case .fat: fat
        }
    }
}

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
