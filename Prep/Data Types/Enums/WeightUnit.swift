import Foundation

enum WeightUnit: Int, CaseIterable, Codable {
    case g = 1
    case kg
    case oz
    case lb
    case mg
}

extension WeightUnit: Unit {
    
    var name: String {
        switch self {
        case .g:    "grams"
        case .kg:   "kilograms"
        case .oz:   "ounces"
        case .lb:   "pounds"
        case .mg:   "milligrams"
        }
    }
    
    var abbreviation: String {
        switch self {
        case .g:    "g"
        case .kg:   "kg"
        case .oz:   "oz"
        case .lb:   "lb"
        case .mg:   "mg"
        }
    }
}

extension WeightUnit {
    var g: Double {
        switch self {
        case .g:
            return 1
        case .kg:
            return 1000
        case .oz:
            return 28.349523
        case .lb:
            return 453.59237
        case .mg:
            return 0.001
        }
    }
}
