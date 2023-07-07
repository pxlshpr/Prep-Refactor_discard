import SwiftUI

struct FoodsViewCell: View {

    let food: Food
    @State var showingForm = false

    init(food: Food) {
        self.food = food
    }
    
    var body: some View {
        Button {
            showingForm = true
        } label: {
            FoodCell(food: food, showingForm: $showingForm)
        }
    }
}
