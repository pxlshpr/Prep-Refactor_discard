import Foundation

enum VolumeUnitType: Int, CaseIterable, Codable {
    case gallon = 1
    case quart
    case pint
    case cup
    case fluidOunce
    case tablespoon
    case teaspoon
    case mL
    case liter
}

extension VolumeUnitType: Unit {
    
    var name: String {
        switch self {
        case .gallon:       "gallons"
        case .quart:        "quarts"
        case .pint:         "pints"
        case .cup:          "cups"
        case .fluidOunce:   "fluid ounces"
        case .tablespoon:   "tablespoons"
        case .teaspoon:     "teaspoons"
        case .mL:           "milliliters"
        case .liter:        "liters"
        }
    }
    
    var abbreviation: String {
        switch self {
        case .gallon:       "gal"
        case .quart:        "qt"
        case .pint:         "pt"
        case .cup:          "cup"
        case .fluidOunce:   "fl oz"
        case .tablespoon:   "tbsp"
        case .teaspoon:     "tsp"
        case .mL:           "mL"
        case .liter:        "L"
        }
    }
}

extension VolumeUnitType {
    static var primaryUnits: [VolumeUnitType] {
        [.mL, .cup, .fluidOunce, .tablespoon, .teaspoon]
    }
    
    static var secondaryUnits: [VolumeUnitType] {
        [.gallon, .liter, .pint, .quart]
    }
}

extension VolumeUnitType {
    var defaultVolumeUnit: VolumeUnit {
        switch self {
        case .gallon:       .gallonUSLiquid
        case .quart:        .quartUSLiquid
        case .pint:         .pintMetric
        case .cup:          .cupMetric
        case .fluidOunce:   .fluidOunceUSNutritionLabeling
        case .tablespoon:   .tablespoonMetric
        case .teaspoon:     .teaspoonMetric
        case .mL:           .mL
        case .liter:        .liter
        }
    }
}
