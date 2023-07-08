import Foundation
import OSLog

private let logger = Logger(subsystem: "FoodItem", category: "")

struct FoodItem: Identifiable, Codable, Hashable {
    let id: UUID
    
    var amount: FoodValue
    var food: Food
    var mealID: UUID?

    var energy: Double
    var energyUnit: EnergyUnit
    var carb: Double
    var fat: Double
    var protein: Double
    
    var largestEnergyInKcal: Double
    
    var sortPosition: Int
    
    var eatenAt: Date?
    var updatedAt: Date
    let createdAt: Date
    
    init(
        id: UUID,
        amount: FoodValue,
        food: Food,
        mealID: UUID?,
        energy: Double,
        energyUnit: EnergyUnit,
        carb: Double,
        fat: Double,
        protein: Double,
        largestEnergyInKcal: Double,
        sortPosition: Int,
        eatenAt: Date?,
        updatedAt: Date,
        createdAt: Date
    ) {
        self.id = id
        self.amount = amount
        self.food = food
        self.mealID = mealID
        self.energy = energy
        self.energyUnit = energyUnit
        self.carb = carb
        self.fat = fat
        self.protein = protein
        self.largestEnergyInKcal = largestEnergyInKcal
        self.sortPosition = sortPosition
        self.eatenAt = eatenAt
        self.updatedAt = updatedAt
        self.createdAt = createdAt
    }
    
    init?(_ entity: FoodItemEntity) {
        self.init(
            id: entity.id!,
            amount: entity.amount,
            food: entity.food,
            mealID: entity.mealID,
            energy: entity.energy,
            energyUnit: entity.energyUnit,
            carb: entity.carb,
            fat: entity.fat,
            protein: entity.protein,
            largestEnergyInKcal: entity.largestEnergyInKcal,
            sortPosition: Int(entity.sortPosition),
            eatenAt: entity.eatenAt,
            updatedAt: entity.updatedAt!,
            createdAt: entity.createdAt!
        )
    }
}

//extension FoodItem {
//    var quantityDescription: String {
//        amount.description(with: food)
//    }
//}

extension FoodValue {
    func unitDescription(sizes: [FoodSize]) -> String {
        switch self.unitType {
        case .serving:
            return "serving"
        case .weight:
            guard let weightUnit else {
                return "invalid weight"
            }
            return weightUnit.abbreviation
        case .volume:
            guard let type = volumeUnit?.type else {
                return "invalid volume"
            }
            return type.abbreviation
        case .size:
            guard let size = sizes.sizeMatchingUnitSizeInFoodValue(self) else {
                return "invalid size"
            }
            if let type = size.volumeUnit?.type {
                return "\(type.abbreviation) \(size.name)"
            } else {
                return size.name
            }
        }
    }
}



import FoodDataTypes
import FoodLabel

extension EnergyUnit {
    var foodLabelUnit: FoodLabelUnit {
        switch self {
        case .kcal: .kcal
        case .kJ:   .kj
        }
    }
}

extension FoodItem {
    var energyFoodLabelValue: FoodLabelValue {
        FoodLabelValue(amount: energy, unit: energyUnit.foodLabelUnit)
    }
    
    var foodLabelData: FoodLabelData {
        FoodLabelData(
            energyValue: energyFoodLabelValue,
            carb: carb,
            fat: fat,
            protein: protein,
            nutrients: microsDictForPreview,
            quantityValue: amount.value,
            quantityUnit: amount.unitDescription(sizes: food.sizes)
        )
    }
    
    /// Used for `FoodLabel`
    var microsDict: [Micro : FoodLabelValue] {
        var dict: [Micro : FoodLabelValue] = [:]
        for nutrientValue in food.micros {
            guard let micro = nutrientValue.micro else { continue }
            dict[micro] = FoodLabelValue(
                amount: calculateMicro(micro),
                unit:
                    nutrientValue.unit.foodLabelUnit
                    ?? micro.defaultUnit.foodLabelUnit
                    ?? .g
            )
        }
        return dict
    }
    
    var microsDictForPreview: [Micro : FoodLabelValue] {
        microsDict
            .filter { $0.key.isIncludedInPreview }
    }

}

//import FoodLabel
//
//extension FoodItemEntity {
//    func foodLabelData(
//        showRDA: Bool,
//        customRDAValues: [AnyNutrient : (Double, NutrientUnit)] = [:],
//        dietName: String? = nil
//    ) -> FoodLabelData {
//
//        let quantityUnit: String
//        if let food {
//            quantityUnit = amount.unitDescription(sizes: food.legacyFood.info.sizes)
//        } else {
//            quantityUnit = ""
//        }
//        return FoodLabelData(
//            energyValue: FoodLabelValue(amount: scaledValueForEnergyInKcal, unit: .kcal),
//            carb: scaledValueForMacro(.carb),
//            fat: scaledValueForMacro(.fat),
//            protein: scaledValueForMacro(.protein),
//            nutrients: microsDict,
//            quantityValue: amount.value,
//            quantityUnit: quantityUnit,
//            showRDA: showRDA,
//            customRDAValues: customRDAValues,
//            dietName: dietName
//        )
//    }
//}
//
//extension FoodItemEntity {
//
//    var scaledValueForEnergyInKcal: Double {
//        guard let food else { return 0 }
//        return food.legacyFood.info.nutrients.energyInKcal * nutrientScaleFactor
//    }
//
//    func scaledValueForMacro(_ macro: Macro) -> Double {
//        guard let food else { return 0 }
//        return food.legacyFood.valueForMacro(macro) * nutrientScaleFactor
//    }
//
//    var microsDict: [NutrientType : FoodLabelValue] {
//        var dict: [NutrientType : FoodLabelValue] = [:]
//        guard let food else { return dict }
//        for nutrient in food.legacyFood.info.nutrients.micros {
//            guard let nutrientType = nutrient.nutrientType
//            else { continue }
//            dict[nutrientType] = FoodLabelValue(
//                amount:
//                    nutrient.value * nutrientScaleFactor,
//                unit:
//                    nutrient.nutrientUnit.foodLabelUnit
//                    ?? nutrientType.defaultUnit.foodLabelUnit
//                    ?? .g
//            )
//        }
//        return dict
//    }
//}
//
//extension NutrientType {
//    var defaultUnit: NutrientUnit {
//        units.first ?? .g
//    }
//}
//


extension FoodItem {
    func calculateEnergy(in unit: EnergyUnit) -> Double {
        food.calculateEnergy(in: unit, for: amount)
    }

    func calculateMacro(_ macro: Macro) -> Double {
        food.calculateMacro(macro, for: amount)
    }
    
    func calculateMicro(_ micro: Micro, in unit: NutrientUnit? = nil) -> Double {
        food.calculateMicro(micro, for: amount, in: unit)
    }
}

extension Food {
    func calculateEnergy(in unit: EnergyUnit, for amount: FoodValue) -> Double {
        guard let value = value(for: .energy) else { return 0 }
        return value.value * nutrientScaleFactor(for: amount)
    }

    func calculateMacro(_ macro: Macro, for amount: FoodValue) -> Double {
        guard let value = value(for: .macro(macro)) else { return 0 }
        return value.value * nutrientScaleFactor(for: amount)
    }

    func calculateMicro(_ micro: Micro, for amount: FoodValue, in unit: NutrientUnit?) -> Double {
        guard let value = value(for: .micro(micro)) else { return 0 }
        
        //TODO: Handle unit conversions
//        let unit = unit ?? micro.defaultUnit
        
        return value.value * nutrientScaleFactor(for: amount)
    }

    private func nutrientScaleFactor(for amount: FoodValue) -> Double {
        guard let quantity = quantity(for: amount) else { return 0 }
        return nutrientScaleFactor(for: quantity) ?? 0
    }
}



extension FoodItem {
    var quantityDescription: String {
        amount.description(with: food)
    }
}

extension Micro {
    var isIncludedInPreview: Bool {
        switch self {
        case .saturatedFat:
            return true
//        case .monounsaturatedFat:
//            return true
//        case .polyunsaturatedFat:
//            return true
        case .transFat:
            return true
        case .cholesterol:
            return true
        case .dietaryFiber:
            return true
//        case .solubleFiber:
//            <#code#>
//        case .insolubleFiber:
//            <#code#>
        case .sugars:
            return true
        case .addedSugars:
            return true
//        case .sugarAlcohols:
//            <#code#>
//        case .calcium:
//            <#code#>
//        case .chloride:
//            <#code#>
//        case .chromium:
//            <#code#>
//        case .copper:
//            <#code#>
//        case .iodine:
//            <#code#>
//        case .iron:
//            <#code#>
//        case .magnesium:
//            return true
//        case .manganese:
//            <#code#>
//        case .molybdenum:
//            <#code#>
//        case .phosphorus:
//            <#code#>
//        case .potassium:
//            return true
//        case .selenium:
//            <#code#>
        case .sodium:
            return true
//        case .zinc:
//            <#code#>
//        case .vitaminA:
//            <#code#>
//        case .vitaminB1_thiamine:
//            <#code#>
//        case .vitaminB2_riboflavin:
//            <#code#>
//        case .vitaminB3_niacin:
//            <#code#>
//        case .vitaminB5_pantothenicAcid:
//            <#code#>
//        case .vitaminB6_pyridoxine:
//            <#code#>
//        case .vitaminB7_biotin:
//            <#code#>
//        case .vitaminB9_folate:
//            <#code#>
//        case .vitaminB9_folicAcid:
//            <#code#>
//        case .vitaminB12_cobalamin:
//            <#code#>
//        case .vitaminC_ascorbicAcid:
//            <#code#>
//        case .vitaminD_calciferol:
//            <#code#>
//        case .vitaminE:
//            <#code#>
//        case .vitaminK1_phylloquinone:
//            <#code#>
//        case .vitaminK2_menaquinone:
//            <#code#>
//        case .choline:
//            <#code#>
//        case .caffeine:
//            <#code#>
//        case .ethanol:
//            <#code#>
//        case .taurine:
//            <#code#>
//        case .polyols:
//            <#code#>
//        case .gluten:
//            <#code#>
//        case .starch:
//            <#code#>
//        case .salt:
//            <#code#>
//        case .creatine:
//            <#code#>
//        case .energyWithoutDietaryFibre:
//            <#code#>
//        case .water:
//            <#code#>
//        case .freeSugars:
//            <#code#>
//        case .ash:
//            <#code#>
//        case .preformedVitaminARetinol:
//            <#code#>
//        case .betaCarotene:
//            <#code#>
//        case .provitaminABetaCaroteneEquivalents:
//            <#code#>
//        case .niacinDerivedEquivalents:
//            <#code#>
//        case .totalFolates:
//            <#code#>
//        case .dietaryFolateEquivalents:
//            <#code#>
//        case .alphaTocopherol:
//            <#code#>
//        case .tryptophan:
//            <#code#>
//        case .linoleicAcid:
//            <#code#>
//        case .alphaLinolenicAcid:
//            <#code#>
//        case .eicosapentaenoicAcid:
//            <#code#>
//        case .docosapentaenoicAcid:
//            <#code#>
//        case .docosahexaenoicAcid:
//            <#code#>
        default:
            return false
        }
    }
}

extension FoodItem: Comparable {
    static func <(lhs: FoodItem, rhs: FoodItem) -> Bool {
        return lhs.sortPosition < rhs.sortPosition
    }
}
