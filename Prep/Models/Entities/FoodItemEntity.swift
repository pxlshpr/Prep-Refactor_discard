import Foundation
import SwiftData
import OSLog

@Model
class FoodItemEntity {
    var uuid: String
    
    var amountRaw: FoodValueRaw
    
    var markedAsEatenAt: Double?
    var sortPosition: Int
    var badgeWidth: Double?
    
    var updatedAt: Double

    var foodID: String
    var mealID: String?

//    @Relationship var foodEntity: FoodEntity?
//    @Relationship var mealEntity: MealEntity?

    init(
        uuid: String = UUID().uuidString,
        foodEntity: FoodEntity?,
        mealEntity: MealEntity?,
        amount: FoodValue,
        markedAsEatenAt: Double? = nil,
        sortPosition: Int,
        updatedAt: Double,
        badgeWidth: Double? = nil
    ) {
        self.uuid = uuid
        
        self.mealID = mealEntity?.uuid
        self.foodID = foodEntity?.uuid ?? ""
        
        self.amount = amount
        
        self.markedAsEatenAt = markedAsEatenAt
        self.sortPosition = sortPosition
        self.updatedAt = updatedAt
        self.badgeWidth = badgeWidth
        
        let logger = Logger(subsystem: "FoodItemEntity", category: "")
        if let mealID = self.mealID {
            logger.debug("Creating FoodItemEntity with mealID: \(mealID, privacy: .public)")
        } else {
            logger.debug("Creating FoodItemEntity with mealID: nil")
        }
    }
    
    var amount: FoodValue {
        get { amountRaw.foodValue }
        set { amountRaw = newValue.rawValue }
    }
    
    var markedAsEatenDate: Date? {
        get {
            guard let markedAsEatenAt else { return nil }
            return Date(timeIntervalSince1970: markedAsEatenAt)
        }
        set { markedAsEatenAt = newValue?.timeIntervalSince1970 }
    }
    
    var updatedDate: Date {
        get { Date(timeIntervalSince1970: updatedAt) }
        set { updatedAt = newValue.timeIntervalSince1970 }
    }
}

extension FoodValue {
    func description(with food: Food) -> String {
        "\(value.cleanAmount) \(unitDescription(sizes: food.sizes))"
    }
    
//    func description(with ingredientFood: IngredientFood) -> String {
//        "\(value.cleanAmount) \(unitDescription(sizes: ingredientFood.info.sizes))"
//    }
}

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

extension FoodItem {
    func scaledEnergyValue(in unit: EnergyUnit) -> Double {
        0
//        guard let value = food.value(for: .energy) else { return 0 }
//        let scaledValue = value.value * nutrientScaleFactor
//        return scaledValue
    }

    func scaledMacroValue(for macro: Macro) -> Double {
        0
//        guard let value = food.value(for: .macro(macro)) else { return 0 }
//        return value.value * nutrientScaleFactor
    }
    
    var nutrientScaleFactor: Double {
        0
//        guard let quantity = food.quantity(for: amount) else { return 0 }
//        return food.nutrientScaleFactor(for: quantity) ?? 0
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
