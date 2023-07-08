import SwiftUI

struct FoodItemsForm: View {
    
    @Bindable var foodModel: FoodModel

    @State var showingFoodPicker = false
    
    var body:  some View {
        form
            .navigationTitle(foodModel.foodItemsName)
    }
    
    var form: some View {
        List {
            foodItemsSection
            energyAndMacrosSection
            microsSection
        }
    }
    
    var foodItemsSection: some View {
        Group {
            Section {
                ForEach(foodModel.foodItems, id: \.self) { foodItem in
                    FoodItemCell(item: foodItem)
                }
            }
            Section {
                addButton
            }
        }
    }
    
    var addButton: some View {
        Button {
            showingFoodPicker = true
        } label: {
            Text("Add \(foodModel.foodItemsSingularName)")
        }
        .popover(isPresented: $showingFoodPicker) { foodPicker }
    }
    
    var foodPicker: some View {
        FoodPicker { foodItem in
            if let foodItem {
                handleNewFoodItem(foodItem)
            }
            showingFoodPicker = false
        }
    }
    
    func handleNewFoodItem(_ foodItem: FoodItem) {
        var foodItem = foodItem
        foodItem.sortPosition = foodModel.lastFoodItemsSortPosition
        foodModel.foodItems.append(foodItem)
        foodModel.setLargestEnergyForAllFoodItems()
    }
    
    var energyAndMacrosSection: some View {
        Section {
        }
    }
    
    var microsSection: some View {
        Section {
        }
    }
}
