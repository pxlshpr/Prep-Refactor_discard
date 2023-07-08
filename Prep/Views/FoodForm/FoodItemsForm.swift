import SwiftUI

import FoodDataTypes

struct FoodItemsForm: View {
    
    @Bindable var foodModel: FoodModel

    @State var showingFoodPicker = false
    @State var showingFoodPickerFromToolbar = false

    var body:  some View {
        form
            .navigationTitle(foodModel.foodItemsName)
            .toolbar { toolbarContent }
            .interactiveDismissDisabled()
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button {
                showingFoodPickerFromToolbar = true
            } label: {
                Image(systemName: "plus")
            }
            .popover(isPresented: $showingFoodPickerFromToolbar) { foodPicker }
        }
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
                    FoodItemCell(foodItem, handleDelete: handleDelete)
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
    
    func handleDelete(_ foodItem: FoodItem) {
        SoundPlayer.play(.octaveSlideScissors)
        var foodItems =  foodModel.foodItems
        foodItems.removeAll(where: { $0.id == foodItem.id })
        handleNewFoodItemsArray(foodItems)
    }
    
    func delete(at offsets: IndexSet) {
        SoundPlayer.play(.octaveSlideScissors)
        var foodItems =  foodModel.foodItems
        foodItems.remove(atOffsets: offsets)
        handleNewFoodItemsArray(foodItems)
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
            showingFoodPickerFromToolbar = false
        }
    }
    
    func handleNewFoodItem(_ foodItem: FoodItem) {
        SoundPlayer.play(.octaveSlidePaper)
        var foodItems =  foodModel.foodItems
        foodItems.append(foodItem)
        handleNewFoodItemsArray(foodItems)
    }
    
    func handleNewFoodItemsArray(_ foodItems: [FoodItem]) {
        var foodItems = foodItems
        foodItems.setLargestEnergy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.snappy) {
                foodModel.foodItems = foodItems
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                calculateNutrients()
            }
        }
    }
    
    func calculateNutrients() {
        withAnimation(.snappy) {
            foodModel.calculateEnergyAndMacros()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.snappy) {
                foodModel.largeChartData = foodModel.macrosChartData
            }
        }
        foodModel.smallChartData = foodModel.macrosChartData

        /// Do this later as its compute intensive and makes the number animations fail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.snappy) {
                foodModel.calculateMicros()
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
            case .macro(let macro):
                Color.clear
                    .animatedItemMacro(
                        value: value(for: nutrient),
                        macro: macro,
                        isPrimary: foodModel.primaryFoodItemsMacro == nutrient.macro,
                        isAnimating: false
                    )
            default:
                EmptyView()

            }
        }
    }
    
    func rowForMicro(_ nutrientValue: NutrientValue) -> some View {
        HStack {
            Text(nutrientValue.nutrient.description)
                .foregroundStyle(Color(.label))
            Spacer()
            Group {
//                Text(valueString(for: nutrient))
                Text(nutrientValue.value.formattedMealItemAmount)
                Text(nutrientValue.unit.abbreviation)
            }
                .foregroundStyle(Color(.secondaryLabel))
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
        Section("Nutrients") {
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
        return Group {
//            ForEach(MicroGroup.allCases, id: \.self) { group in
//            ForEach(foodModel.microGroups.nonEmptyGroups, id: \.self) { group in
            ForEach(foodModel.constructedMicroGroups, id: \.self) { group in
                Section(group.name) {
//                    ForEach(group.micros, id: \.self) { micro in
//                        let nutrientValue = NutrientValue(micro: micro)
//                        rowForMicro(nutrientValue)
//                    }
                    ForEach((foodModel.microGroups[group] ?? []), id: \.self) { nutrientValue in
                        rowForMicro(nutrientValue)
                    }
                }
            }
        }
    }
}

extension Sequence where Iterator.Element == (key: MicroGroup, value: [NutrientValue]) {
    var nonEmptyGroups: [MicroGroup] {
        self
            .filter { !$0.value.isEmpty } /// Filter out all the groups that aren't empty
            .map { $0.key } /// Only returning the keys
            .sorted()
    }
}
