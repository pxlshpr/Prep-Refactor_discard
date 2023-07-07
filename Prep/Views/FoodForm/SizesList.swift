import SwiftUI

struct SizesList: View {
    
    @Environment(FoodModel.self) var foodModel: FoodModel
    @State var showingFormOnToolbar: Bool = false
    @State var showingFormOnCell: Bool = false

    var body: some View {
        List {
            Section(footer: footer) {
                ForEach(foodModel.sizes.sorted(), id: \.self) { size in
                    SizeCell(size: size)
                }
                .onDelete { offsets in
                    foodModel.removeSizes(at: offsets)
                }
                addSizeButton
            }
            densitySection
        }
        .toolbar { toolbarContent }
        .navigationTitle("Other Sizes")
    }
    
    @ViewBuilder
    var addSizeButton: some View {
        if foodModel.sizes.isEmpty {
            Button {
                foodModel.newSize = FormSize()
                showingFormOnCell = true
            } label: {
                Text("New Size")
            }
            .popover(isPresented: $showingFormOnCell) { sizeForm }
        }
    }
    
    var footer: some View {
        let forIngredients = false
        let foodType: FoodType = .food
        var footerString: String {
            let examples = forIngredients
            ? "bowl, small tupperware, shaker bottle, etc."
            : "biscuit, bottle, container, etc."
            return "Sizes give you additional portions to log this \(foodType) in; like \(examples)"
        }
        
        return Text(footerString)
    }
    
    var sizeForm: some View {
        SizeForm(foodModel: foodModel)
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                foodModel.newSize = FormSize()
                showingFormOnToolbar = true
            } label: {
                Image(systemName: "plus")
            }
            .popover(isPresented: $showingFormOnToolbar) { sizeForm }
        }
    }
}

extension SizesList {
    
    var densityFields: some View {
        var volumeTextField: some View {
            let binding = Binding<Double>(
                get: { foodModel.volumeValue },
                set: { newValue in
                    foodModel.volumeValue = newValue
                }
            )

            return TextField("", value: binding, formatter: NumberFormatter.foodValue)
                .textFieldStyle(.plain)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }

        var weightTextField: some View {
            let binding = Binding<Double>(
                get: { foodModel.weightValue },
                set: { newValue in
                    foodModel.weightValue = newValue
                }
            )

            return TextField("", value: binding, formatter: NumberFormatter.foodValue)
                .textFieldStyle(.plain)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }

        var volumeUnitMenu: some View {
            
            func button(_ formUnit: FormUnit) -> some View {
                Button {
                    foodModel.volumeUnit = formUnit
                } label: {
                    Text("\(formUnit.name) (\(formUnit.abbreviation))")
                }
            }
            
            return Menu {
                ForEach(VolumeUnitType.primaryUnits, id: \.self) { volumeUnit in
                    button(.volume(volumeUnit.defaultVolumeUnit))
                }
                Section("Others") {
                    ForEach(VolumeUnitType.secondaryUnits, id: \.self) { volumeUnit in
                        button(.volume(volumeUnit.defaultVolumeUnit))
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(foodModel.volumeUnit.abbreviation)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .foregroundStyle(Color(.secondaryLabel))
            }
            .padding(.leading, 5)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .hoverEffect(.highlight)
        }
        
        var weightUnitMenu: some View {
            
            func button(_ formUnit: FormUnit) -> some View {
                Button {
                    foodModel.weightUnit = formUnit
                } label: {
                    Text("\(formUnit.name) (\(formUnit.abbreviation))")
                }
            }
            
            return Menu {
                ForEach(WeightUnit.allCases, id: \.self) { weightUnit in
                    button(.weight(weightUnit))
                }
            } label: {
                HStack(spacing: 4) {
                    Text(foodModel.weightUnit.abbreviation)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .foregroundStyle(Color(.secondaryLabel))
            }
            .padding(.leading, 5)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .hoverEffect(.highlight)
        }
        
        return Group {
            HStack {
                Text("Volume")
                Spacer()
                volumeTextField
                volumeUnitMenu
            }
            HStack {
                Text("Weight")
                Spacer()
                weightTextField
                weightUnitMenu
            }
        }
    }
    
    var densitySection: some View {
        var addButton: some View {
            Button("Add Unit Conversion") {
                withAnimation(.snappy) {
                    foodModel.hasDensity = true
                    foodModel.setSaveDisabled()
                }
            }
        }
        
        var removeButton: some View {
            Button {
                withAnimation(.snappy) {
                    foodModel.hasDensity = false
                    foodModel.setSaveDisabled()
                }
            } label: {
                Text("Remove")
                    .font(.footnote)
            }
        }
        
//        @ViewBuilder
        var footer: some View {
//            if !foodModel.hasDensity {
                Text("e.g. 1 cup = 200 g")
//            }
        }
        
        @ViewBuilder
        var header: some View {
            if foodModel.hasDensity {
                HStack {
                    Text("Unit Conversion")
                    Spacer()
                    removeButton
                }
            }
        }

        return Section(header: header, footer: footer) {
            if foodModel.hasDensity {
                densityFields
            } else {
                addButton
            }
        }
    }
    
}

struct SizeCell: View {
    
    @Environment(FoodModel.self) var foodModel: FoodModel

    let size: FormSize
    @State var showingForm: Bool = false

    var body: some View {
        Button {
            foodModel.newSize = size
            foodModel.sizeBeingEdited = size
            showingForm = true
        } label: {
            HStack {
                Text("\(size.quantityString)\(size.fullName)")
                    .foregroundStyle(Color(.label))
                Spacer()
                Text("\(size.amountString)")
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
        .popover(isPresented: $showingForm) { sizeForm }
    }
    
    var sizeForm: some View {
        SizeForm(foodModel: foodModel)
    }
}
