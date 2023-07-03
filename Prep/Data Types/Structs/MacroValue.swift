import Foundation

import FoodDataTypes

struct MacroValue {
    var macro: Macro
    var value: Double
    
    var kcal: Double {
        macro.kcalsPerGram * value
    }
}

