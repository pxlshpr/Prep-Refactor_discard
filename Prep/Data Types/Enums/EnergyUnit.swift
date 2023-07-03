//import Foundation
//
//enum EnergyUnit: Int, CaseIterable, Codable {
//    case kcal = 1
//    case kJ
//}
//
//extension EnergyUnit {
//    var name: String {
//        switch self {
//        case .kcal:
//            return "Kilocalorie"
//        case .kJ:
//            return "Kilojule"
//        }
//    }
//    
//    var abbreviation: String {
//        switch self {
//        case .kcal:
//            return "kcal"
//        case .kJ:
//            return "kJ"
//        }
//    }
//}
//
//extension EnergyUnit {
//    var nutrientUnit: NutrientUnit {
//        switch self {
//        case .kcal: .kcal
//        case .kJ:   .kJ
//        }
//    }
//}
