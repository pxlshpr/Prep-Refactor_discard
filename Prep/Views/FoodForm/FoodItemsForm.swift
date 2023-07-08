import SwiftUI

import FoodDataTypes

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
        .listStyle(.grouped)
    }
    
    var foodItemsSection: some View {
        Group {
            Section {
                ForEach(foodModel.foodItems) { foodItem in
                    FoodItemCell(item: foodItem)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            }
            Section {
                addButton
            }
        }
    }
    
    func delete(at offsets: IndexSet) {
        foodModel.foodItems.remove(atOffsets: offsets)
//        SoundPlayer.play(.letterpressDelete)
        SoundPlayer.play(.octaveSlideScissors)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            handleNutrientsChange()
//        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        foodModel.foodItems.move(fromOffsets: source, toOffset: destination)
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
//        SoundPlayer.play(.clearSwoosh)
        SoundPlayer.play(.octaveSlidePaper)

        var foodItems =  foodModel.foodItems
        foodItems.append(foodItem)
        foodItems.setLargestEnergy()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.snappy) {
                foodModel.foodItems = foodItems
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                handleNutrientsChange()
            }
        }
    }
    
    func handleNutrientsChange() {
        withAnimation(.snappy) {
            foodModel.calculateNutrients()
        }
        
        foodModel.smallChartData = self.foodModel.macrosChartData
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.snappy) {
                foodModel.largeChartData = foodModel.macrosChartData
            }
        }
    }
    
    func field(for nutrient: Nutrient) -> some View {
        HStack {
            Text(nutrient.description)
                .foregroundStyle(Color(.label))
            Spacer()
            switch nutrient {
            case .energy:
                Color.clear
                    .animatedItemEnergy(
                        value: value(for: .energy),
                        energyUnit: .kcal,
                        isAnimating: false
                    )
            case .macro:
                Color.clear
                    .animatedItemMacro(
                        value: value(for: nutrient),
                        macro: nutrient.macro!,
                        isPrimary: foodModel.primaryFoodItemsMacro == nutrient.macro,
                        isAnimating: false
                    )

            case .micro:
                Text(valueString(for: nutrient))
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
    }
    
    func value(for nutrient: Nutrient) -> Double {
        foodModel.value(for: nutrient)
    }

    func unit(for nutrient: Nutrient) -> NutrientUnit {
        switch nutrient {
        case .energy:           .kcal
        case .macro:            .g
        case .micro(let micro): micro.defaultUnit
        }
    }

    func valueString(for nutrient: Nutrient) -> String {
        "\(value(for: nutrient).cleanAmount) \(unit(for: nutrient).abbreviation)"
    }

    var energyAndMacrosSection: some View {
        Section {
            HStack {
                Text("Energy")
                    .foregroundStyle(Color(.label))
                Spacer()
                Color.clear
                    .animatedItemEnergy(
                        value: value(for: .energy),
                        energyUnit: .kcal,
                        isAnimating: false
                    )
            }
//            field(for: .energy)
            
            ForEach(Macro.allCases, id: \.self) {
                field(for: .macro($0))
            }
            
            MacrosPieChart(foodModel: foodModel)
        }
    }
    
    var microsSection: some View {
        Section {
        }
    }
}
