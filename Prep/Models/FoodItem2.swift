import Foundation

struct FoodItem2 {
    let id: UUID
    
    var amount: FoodValue
    var food: Food2

    var badgeWidth: CGFloat
    var sortPosition: Int
    
    var eatenAt: Date
    var updatedAt: Date
    let createdAt: Date
}
