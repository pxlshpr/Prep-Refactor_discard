import Foundation

enum ItemFormAction {
    case saveMealItem(FoodItemEntity, MealEntity)
    case saveIngredientItem(FoodItemEntity)
    case delete
    case dismiss
}
