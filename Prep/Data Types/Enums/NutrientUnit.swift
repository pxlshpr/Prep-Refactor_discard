//import Foundation
//import FoodDataTypes
//
//enum NutrientUnit: Int, CaseIterable, Codable {
//    case g = 1
//    case mg
//    case mgAT /// alpha-tocopherol
//    case mgNE
//    case mcg = 50
//    case mcgDFE
//    case mcgRAE
//    case IU = 100
//    case p /// percent
//    case kcal = 200
//    case kJ
//    
//    /// Used by USDA
//    case pH = 300
//    case SG
//    case mcmolTE
//    case mgGAE
//}
//
//extension NutrientUnit {
//    var abbreviation: String {
//        switch self {
//        case .g:        "g"
//        case .mg:       "mg"
//        case .mgAT:     "mgAT"
//        case .mgNE:     "mgNE"
//        case .mcg:      "mcg"
//        case .mcgDFE:   "mcgDFE"
//        case .mcgRAE:   "mcgRAE"
//        case .IU:       "IU"
//        case .p:        "p"
//        case .kcal:     "kcal"
//        case .kJ:       "kJ"
//        case .pH:       "pH"
//        case .SG:       "SG"
//        case .mcmolTE:  "mcmolTE"
//        case .mgGAE:    "mgGAE"
//        }
//    }
//}
//
//extension NutrientUnit {
//    var foodLabelUnit: FoodLabelUnit? {
//        switch self {
//        case .g:
//            return .g
//        case .mcg, .mcgDFE, .mcgRAE:
//            return .mcg
//        case .mg, .mgAT, .mgNE:
//            return .mg
//        case .p:
//            return .p
//        case .IU:
//            return .iu
//        case .kcal:
//            return .kcal
//        case .kJ:
//            return .kj
//                        
//        /// Used by the USDA Database
//        case .pH, .SG, .mcmolTE, .mgGAE:
//            return nil
//        }
//    }
//    
//    var energyUnit: EnergyUnit? {
//        switch self {
//        case .kcal: .kcal
//        case .kJ:   .kJ
//        default:    nil
//        }
//    }
//}
