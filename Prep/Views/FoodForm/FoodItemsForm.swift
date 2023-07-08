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
                ForEach(foodModel.foodItems) { foodItem in
                    FoodItemCell(item: foodItem)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
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
        SoundPlayer.play(.clearSwoosh)

        var foodItems =  foodModel.foodItems
        foodItems.append(foodItem)
        foodItems.setLargestEnergy()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                foodModel.foodItems = foodItems
//                foodModel.foodItems.append(foodItem)
            }
            
//            foodModel.calculateNutrients()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                withAnimation {
//                    foodModel.setLargestEnergyForAllFoodItems()
//                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    foodModel.smallChartData = self.foodModel.macrosChartData
                    withAnimation(.snappy) {
                        foodModel.largeChartData = foodModel.macrosChartData
                    }
                }
            }

        }
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
