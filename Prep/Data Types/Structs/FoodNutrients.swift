import Foundation

struct FoodNutrients: Codable, Hashable {
    var energyInKcal: Double
    var carb: Double
    var protein: Double
    var fat: Double
    var micros: [FoodNutrient]
}

//MARK: - Raw Value

extension FoodNutrients {
    var rawValue: FoodNutrientsRaw {
        FoodNutrientsRaw(foodNutrients: self)
    }
}

struct FoodNutrientsRaw: Codable, Hashable {
    var energyInKcal: Double
    var carb: Double
    var protein: Double
    var fat: Double
    var microsValue: [FoodNutrientRaw]
    
    init(foodNutrients: FoodNutrients) {
        self.init(
            energyInKcal: foodNutrients.energyInKcal,
            carb: foodNutrients.carb,
            protein: foodNutrients.protein,
            fat: foodNutrients.fat,
            microsValue: foodNutrients.micros.map { $0.rawValue }
        )
    }
    
    var foodNutrients: FoodNutrients {
        FoodNutrients(
            energyInKcal: energyInKcal,
            carb: carb,
            protein: protein,
            fat: fat,
            micros: micros
        )
    }
    
    init(
        energyInKcal: Double,
        carb: Double,
        protein: Double,
        fat: Double,
        microsValue: [FoodNutrientRaw]
    ) {
        self.energyInKcal = energyInKcal
        self.carb = carb
        self.protein = protein
        self.fat = fat
        self.microsValue = microsValue
    }
    
    var micros: [FoodNutrient] {
        get {
            microsValue.map { $0.foodNutrient }
        }
        set {
            microsValue = newValue.map { $0.rawValue }
        }
    }
}

