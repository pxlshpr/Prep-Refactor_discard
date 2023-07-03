import Foundation

struct FoodItem: Identifiable {
    
    var id: String = UUID().uuidString
    var amount: FoodValue = FoodValue(100, .weight(.g))
    var markedAsEatenDate: Date? = nil
    var sortPosition: Int = 0
    var badgeWidth: Double? = nil
    var updatedDate: Date = Date.now

    var food: Food = Food()
    var mealID: String? = nil
    
    init() { }
    
    init(
        _ entity: FoodItemEntity,
        foodEntity: FoodEntity
    ) {
        self.init()
        self.id = entity.uuid
        self.amount = entity.amount
        self.markedAsEatenDate = entity.markedAsEatenDate
        self.sortPosition = entity.sortPosition
        self.badgeWidth = entity.badgeWidth
        self.updatedDate = entity.updatedDate
//        self.food = foodEntity.food
        self.food = Food()
        self.mealID = entity.mealID
    }
}

extension FoodItem {
    var quantityDescription: String {
        amount.description(with: food)
    }
}
