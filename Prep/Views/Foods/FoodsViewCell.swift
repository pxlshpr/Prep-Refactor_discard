import SwiftUI

struct FoodsViewCell: View {

    let food: Food
    @Binding var foodBeingEdited: Food?

    var body: some View {
        Button {
            foodBeingEdited = food
        } label: {
            FoodCell(food: food, foodBeingEdited: $foodBeingEdited)
        }
    }
}
