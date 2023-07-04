import SwiftUI

import FoodDataTypes

enum NutrientMeterComponent: Codable {
    case energy(unit: EnergyUnit)
    case macro(Macro)
    case micro(micro: Micro, unit: NutrientUnit)
}

extension NutrientMeterComponent {
    var textColor: Color {
        switch self {
        case .energy:
            return Color("StatsEnergyText")
        case .macro(let macro):
            switch macro {
            case .carb:     return Color("StatsCarbText")
            case .fat:      return Color("StatsFatText")
            case .protein:  return Color("StatsProteinText")
            }
        case .micro:
            return Color("StatsMicroText")
        }
    }
    
    var preppedColor: Color {
        switch self {
        case .energy:
            return Color("StatsEnergyPlaceholder")
        case .macro(let macro):
            switch macro {
            case .carb:     return Color("StatsCarbPlaceholder")
            case .fat:      return Color("StatsFatPlaceholder")
            case .protein:  return Color("StatsProteinPlaceholder")
            }
        case .micro:
            return Color("StatsMicroPlaceholder")
        }
    }
    
    var eatenColor: Color {
        switch self {
        case .energy:
            return Color("StatsEnergyFill")
        case .macro(let macro):
            switch macro {
            case .carb:     return Color("StatsCarbFill")
            case .fat:      return Color("StatsFatFill")
            case .protein:  return Color("StatsProteinFill")
            }
        case .micro:
            return Color("StatsMicroFill")
        }
    }

}
