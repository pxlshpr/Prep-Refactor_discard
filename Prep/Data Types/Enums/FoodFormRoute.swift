import Foundation

enum FoodFormRoute: String, Hashable {
    case emojiPicker
    case nutrients
    case sizes    
}


extension FoodFormRoute: CustomStringConvertible {
    var description: String {
        self.rawValue
    }
}
