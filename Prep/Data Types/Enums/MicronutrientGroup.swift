//import Foundation
//
//enum MicroGroup: Int, CaseIterable, Codable {
//    case fats = 1
//    case fibers
//    case sugars
//    case minerals
//    case vitamins
//    case misc
//}
//
//extension MicroGroup {
//    var name: String {
//        switch self {
//        case .fats:
//            return "Fats"
//        case .fibers:
//            return "Fibers"
//        case .sugars:
//            return "Sugars"
//        case .minerals:
//            return "Minerals"
//        case .vitamins:
//            return "Vitamins"
//        case .misc:
//            return "Miscellaneous"
//        }
//    }
//    
//    var micros: [Micro] {
//        Micro
//            .allCases
//            .filter { $0.group == self }
//    }
//}
//
//extension MicroGroup {
//    var supportsPercentages: Bool {
//        switch self {
//        case .vitamins, .minerals:  true
//        default:                    false
//        }
//    }
//}
