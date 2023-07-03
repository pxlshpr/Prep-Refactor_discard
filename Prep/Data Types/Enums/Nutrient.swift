import Foundation

import FoodDataTypes

enum Nutrient: Codable, Hashable {
    case energy
    case macro(Macro)
    case micro(Micro)
    
    var description: String {
        switch self {
        case .energy:
            "Energy"
        case .macro(let macro):
            macro.name
        case .micro(let micro):
            micro.name
        }
    }
    
    var macro: Macro? {
        switch self {
        case .macro(let macro): macro
        default:                nil
        }
    }
    
    var isEnergy: Bool {
        switch self {
        case .energy:
            return true
        default:
            return false
        }
    }
    
    var micro: Micro? {
        switch self {
        case .micro(let micro):
            return micro
        default:
            return nil
        }
    }
    
    var isMandatory: Bool {
        switch self {
        case .micro:
            return false
        default:
            return true
        }
    }
    
    var defaultFoodLabelUnit: FoodLabelUnit {
        switch self {
        case .energy:
            .kcal
        case .macro:
            .g
        case .micro(let nutrientType):
            nutrientType.supportedNutrientUnits.first?.foodLabelUnit ?? .g
        }
    }
}

extension Nutrient: Identifiable {
    var id: String { description }
}

//MARK: - Attribute+Nutrient
extension Attribute {
    var nutrient: Nutrient? {
        if self == .energy {
            return .energy
        }
        if let macro {
            return .macro(macro)
        }
        if let micro {
            return .micro(micro)
        }
        return nil
    }
}

import FoodDataTypes

extension Nutrient {
    static var macros: [Nutrient] {
        [
            .macro(.carb),
            .macro(.fat),
            .macro(.protein),
        ]
    }
}
