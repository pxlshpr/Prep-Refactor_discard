import SwiftUI

struct FoodsViewCell: View {

    let food: Food2
    @State var showingForm = false

    init(food: Food2) {
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
