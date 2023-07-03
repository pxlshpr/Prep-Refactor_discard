//import SwiftUI
//import SwiftData
//import Observation
//import OSLog
//
//private let logger = Logger(subsystem: "ItemForm", category: "ItemForm")
//
//@Observable class ItemModel {
//    
//    var showingItem = false
//    
//    var amount: Double = DefaultAmount
//    var unit: FormUnit = DefaultUnit
//    
//    var foodResult: FoodResult? = nil
//    var meal: Meal? = nil
//    var foodItem: FoodItem? = nil
//
//    init(
//        showingItem: Bool = false,
//        amount: Double = DefaultAmount,
//        unit: FormUnit = DefaultUnit,
//        foodResult: FoodResult? = nil,
//        meal: Meal? = nil,
//        foodItem: FoodItem? = nil
//    ) {
//        self.showingItem = showingItem
//        self.amount = amount
//        self.unit = unit
//        self.foodResult = foodResult
//        self.meal = meal
//        self.foodItem = foodItem
//    }
//    
//    func setFoodResult(_ foodResult: FoodResult) {
//        self.foodResult = foodResult
//    }
//    
//    func reset() {
//        self.foodResult = nil
//        self.amount = DefaultAmount
//        self.unit = DefaultUnit
//        self.meal = nil
//        self.foodItem = nil
//    }
//    
//    var foodValue: FoodValue {
//        FoodValue(amount, unit)
//    }
//    
//    var amountBinding: Binding<Double> {
//        Binding<Double>(
//            get: { self.amount },
//            set: { newValue in
//                self.amount = newValue
//                self.setSaveDisabled()
//            }
//        )
//    }
//
//    var unitBinding: Binding<FormUnit> {
//        Binding<FormUnit>(
//            get: { self.unit },
//            set: { newValue in
//                withAnimation(.snappy) {
//                    self.unit = newValue
//                }
//            }
//        )
//    }
//    
//    func setSaveDisabled() {
//        
//    }
//}
