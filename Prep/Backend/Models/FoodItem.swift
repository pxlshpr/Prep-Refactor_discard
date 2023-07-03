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
    var badgeWidth: CGFloat
    
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
        badgeWidth: CGFloat,
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
        self.badgeWidth = badgeWidth
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
            badgeWidth: entity.badgeWidth,
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

//extension FoodItem {
//    func scaledEnergyValue(in unit: EnergyUnit) -> Double {
//        0
////        guard let value = food.value(for: .energy) else { return 0 }
////        let scaledValue = value.value * nutrientScaleFactor
////        return scaledValue
//    }
//
//    func scaledMacroValue(for macro: Macro) -> Double {
//        0
////        guard let value = food.value(for: .macro(macro)) else { return 0 }
////        return value.value * nutrientScaleFactor
//    }
//
//    var nutrientScaleFactor: Double {
//        0
////        guard let quantity = food.quantity(for: amount) else { return 0 }
////        return food.nutrientScaleFactor(for: quantity) ?? 0
//    }
//}


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
    func scaledEnergyValue(in unit: EnergyUnit) -> Double {
        guard let value = food.value(for: .energy) else { return 0 }
        let scaledValue = value.value * nutrientScaleFactor
        return scaledValue
    }

    func scaledMacroValue(for macro: Macro) -> Double {
        guard let value = food.value(for: .macro(macro)) else { return 0 }
        return value.value * nutrientScaleFactor
    }
    
    var nutrientScaleFactor: Double {
        guard let quantity = food.quantity(for: amount) else { return 0 }
        return food.nutrientScaleFactor(for: quantity) ?? 0
    }
}


extension FoodItem {
    var quantityDescription: String {
        amount.description(with: food)
    }
}
