import Foundation
//import SwiftData
import OSLog

//@Model
//class FoodItemEntity {
//    var uuid: String
//    
//    var amountRaw: FoodValueRaw
//    
//    var markedAsEatenAt: Double?
//    var sortPosition: Int
//    var badgeWidth: Double?
//    
//    var updatedAt: Double
//
//    var foodID: String
//    var mealID: String?
//
////    @Relationship var foodEntity: FoodEntity?
////    @Relationship var mealEntity: MealEntity?
//
//    init(
//        uuid: String = UUID().uuidString,
//        foodEntity: FoodEntity?,
//        mealEntity: MealEntity?,
//        amount: FoodValue,
//        markedAsEatenAt: Double? = nil,
//        sortPosition: Int,
//        updatedAt: Double,
//        badgeWidth: Double? = nil
//    ) {
//        self.uuid = uuid
//        
//        self.mealID = mealEntity?.uuid
//        self.foodID = foodEntity?.uuid ?? ""
//        
//        self.amount = amount
//        
//        self.markedAsEatenAt = markedAsEatenAt
//        self.sortPosition = sortPosition
//        self.updatedAt = updatedAt
//        self.badgeWidth = badgeWidth
//        
//        let logger = Logger(subsystem: "FoodItemEntity", category: "")
//        if let mealID = self.mealID {
//            logger.debug("Creating FoodItemEntity with mealID: \(mealID, privacy: .public)")
//        } else {
//            logger.debug("Creating FoodItemEntity with mealID: nil")
//        }
//    }
//    
//    var amount: FoodValue {
//        get { amountRaw.foodValue }
//        set { amountRaw = newValue.rawValue }
//    }
//    
//    var markedAsEatenDate: Date? {
//        get {
//            guard let markedAsEatenAt else { return nil }
//            return Date(timeIntervalSince1970: markedAsEatenAt)
//        }
//        set { markedAsEatenAt = newValue?.timeIntervalSince1970 }
//    }
//    
//    var updatedDate: Date {
//        get { Date(timeIntervalSince1970: updatedAt) }
//        set { updatedAt = newValue.timeIntervalSince1970 }
//    }
//}

extension FoodValue {
    func description(with food: Food) -> String {
        "\(value.cleanAmount) \(unitDescription(sizes: food.sizes))"
    }
    
//    func description(with ingredientFood: IngredientFood) -> String {
//        "\(value.cleanAmount) \(unitDescription(sizes: ingredientFood.info.sizes))"
//    }
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
