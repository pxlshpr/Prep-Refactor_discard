import Foundation

enum FoodType: Int, Codable, CaseIterable {
    case food = 1
    case recipe
    case plate
}

extension FoodType: CustomStringConvertible {
    var description: String {
        switch self {
        case .food:     "food"
        case .recipe:   "recipe"
        case .plate:    "plate"
        }
    }
}
