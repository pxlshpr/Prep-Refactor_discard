//import Foundation
//import FoodDataTypes
//
///**
// A value that can appear in a Food Label.
// 
// This comprises of an amount and an optional `FoodLabelUnit`.
// */
//struct FoodLabelValue: Codable {
//    var amount: Double
//    var unit: FoodLabelUnit?
//    
//    init(amount: Double, unit: FoodLabelUnit? = nil) {
//        self.amount = amount
//        self.unit = unit
//    }
//}
//
//extension FoodLabelValue: Equatable {
//    static func ==(lhs: FoodLabelValue, rhs: FoodLabelValue) -> Bool {
//        lhs.amount == rhs.amount &&
//        lhs.unit == rhs.unit
//    }
//}
