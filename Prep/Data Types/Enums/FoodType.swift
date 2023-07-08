import Foundation

enum FoodType: Int, Codable, CaseIterable {
    case food = 1
    case recipe
    case plate
}

extension FoodType: Identifiable {
    var id: Int { rawValue }
}

extension FoodType {
    var systemImage: String {
        switch self {
        case .food:     "carrot"
        case .plate:    "fork.knife"
        case .recipe:   "frying.pan"
        }
    }
    
    var name: String {
        switch self {
        case .food:     "Food"
        case .recipe:   "Recipe"
        case .plate:    "Plate"
        }
    }
}
