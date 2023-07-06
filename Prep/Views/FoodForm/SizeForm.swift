import SwiftUI

import SwiftHaptics

struct SizeForm: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State var showingDuplicateAlert: Bool = false
    
    var foodModel: FoodModel
    
    var body: some View {
        NavigationStack {
            Form {
                fieldSection
                toggleSection
            }
            .navigationTitle(isEditing ? "Edit Size" : "New Size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .presentationDetents([.height(450)])
        .frame(idealWidth: 400, idealHeight: 390)
        .alert(duplicateMessage, isPresented: $showingDuplicateAlert, actions: { })
    }
    
    var duplicateMessage: String {
        "A size with that name already exists."
    }
    
    var toggleSection: some View {
        let binding = Binding<Bool>(
            get: {  foodModel.newSize.isVolumePrefixed },
            set: { newValue in
                withAnimation(.snappy) {
                    foodModel.newSize.volumeUnit = newValue
                    ? VolumeUnitType.cup.defaultVolumeUnit
                    : nil
                    
                    /// If we've made this a volume-based unit and the current unit isn't a weight,
                    /// switch it to grams (as only weight untis are allowed with volume-based units.
                    if newValue, !foodModel.newSize.unit.isWeight {
                        foodModel.newSize.unit = .weight(.g)
                    }
                }
            }
        )
        
        var footer: some View {
            Text("This will let you log this food in volumes of different densities or thicknesses, like – ‘cups shredded’, ‘cups sliced’.")
                .foregroundStyle(Color(.secondaryLabel))
        }

        return Section(footer: footer) {
            Toggle("Volume based", isOn: binding)
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    guard foodModel.canSaveNewSize else {
                        Haptics.errorFeedback()
                        showingDuplicateAlert = true
                        return
                    }
                    
                    Haptics.selectionFeedback()
                    withAnimation(.snappy) {
                        foodModel.saveSize()
                    }
                    dismiss()
                } label: {
                    Text(isEditing ? "Done" : "Add")
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    var isEditing: Bool {
        foodModel.sizeBeingEdited != nil
    }
    
    var fieldSection: some View {
        var footer: some View {
            if foodModel.newSize.isVolumePrefixed {
                Text("e.g. 2 × cup, shredded = 125 g")
            } else {
                Text("e.g. 5 × cookies = 58 g")
            }
        }

        return Section(footer: footer) {
            field
        }
    }
    
    var field: some View {
        VStack {
            HStack {
                multiplySymbol
                    .opacity(0)
                Spacer()
                quantityField
            }
            .frame(height: 38)
            HStack {
                multiplySymbol
                Spacer()
                HStack(spacing: 0) {
                    if foodModel.newSize.isVolumePrefixed {
                        volumeField
                        volumeCommaSymbol
                    }
                    nameField
                }
            }
            .frame(height: 38)
            HStack {
                equalsSymbol
                Spacer()
                amountField
            }
            .frame(height: 38)
        }
    }

    var volumeField: some View {
        volumeUnitMenu
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 12)
            .frame(minWidth: 80)
            .background(background)
    }
    
    var volumeUnitMenu: some View {
        
        func button(_ formUnit: FormUnit) -> some View {
            Button {
                foodModel.newSize.volumeUnit = formUnit.volumeUnit
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
                Text(foodModel.newSize.volumeUnit?.abbreviation ?? "")
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
    
    var volumeCommaSymbol: some View {
        symbol(", ")
            .transition(.opacity)
    }
    var equalsSymbol: some View {
        symbol("=")
    }

    var quantityField: some View {
        let binding = Binding<Double>(
            get: { foodModel.newSize.quantity ?? 1 },
            set: { newValue in
                foodModel.newSize.quantity = newValue
            }
        )
        
        return TextField("1", value: binding, formatter: NumberFormatter.foodValue)
            .textFieldStyle(.plain)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 12)
            .background(background)
    }

    var amountField: some View {
        Grid {
            GridRow {
                amountTextField
                amountUnitMenu
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.trailing, 20)
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 12)
        .background(background)
    }
    
    var amountTextField: some View {
        let binding = Binding<Double>(
            get: { foodModel.newSize.amount ?? 100 },
            set: { newValue in
                foodModel.newSize.amount = newValue
            }
        )

        return TextField("", value: binding, formatter: NumberFormatter.foodValue)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .textInputAutocapitalization(.never)
            .keyboardType(.decimalPad)
    }

    var amountUnitMenu: some View {
        
        func button(_ formUnit: FormUnit) -> some View {
            Button {
                foodModel.newSize.unit = formUnit
            } label: {
                Text("\(formUnit.name) (\(formUnit.abbreviation))")
            }
        }
        
        var weightOptions: some View {
            Group {
                ForEach(WeightUnit.allCases, id: \.self) { weightUnit in
                    button(.weight(weightUnit))
                }
            }
        }
        
        var sizesSection: some View {
            Section("Sizes") {
                ForEach(foodModel.sizes.sorted(), id: \.self) { size in
                    if size.isVolumePrefixed {
                        Menu {
                            ForEach(VolumeUnitType.primaryUnits, id: \.self) { volumeUnit in
                                Button {
                                    foodModel.newSize.unit = .size(size, volumeUnit.defaultVolumeUnit)
                                } label: {
                                    Text("\(volumeUnit.name) (\(volumeUnit.abbreviation))")
                                }
                            }
                            Section("Others") {
                                ForEach(VolumeUnitType.secondaryUnits, id: \.self) { volumeUnit in
                                    Button {
                                        foodModel.newSize.unit = .size(size, volumeUnit.defaultVolumeUnit)
                                    } label: {
                                        Text("\(volumeUnit.name) (\(volumeUnit.abbreviation))")
                                    }
                                }
                            }
                        } label: {
                            Text(size.name)
                        }
                    } else {
                        Button {
                            foodModel.newSize.unit = .size(size, nil)
                        } label: {
                            Text(size.name)
                        }
                    }
                }
            }
        }
        
        var allOptions: some View {
            Group {
                Section {
                    if foodModel.hasServing {
                        Button {
                            foodModel.newSize.unit = .serving
                        } label: {
                            Text("Serving")
                        }
                    }
                    Menu {
                        weightOptions
                    } label: {
                        Text("Weights")
                    }
                    Menu {
                        ForEach(VolumeUnitType.primaryUnits, id: \.self) { volumeUnit in
                            button(.volume(volumeUnit.defaultVolumeUnit))
                        }
                        Section("Others") {
                            ForEach(VolumeUnitType.secondaryUnits, id: \.self) { volumeUnit in
                                button(.volume(volumeUnit.defaultVolumeUnit))
                            }
                        }
                    } label: {
                        Text("Volumes")
                    }
                }
                sizesSection
            }
        }
        
        return Menu {
            if foodModel.newSize.isVolumePrefixed {
                weightOptions
            } else {
                allOptions
            }
        } label: {
            HStack(spacing: 4) {
                Text(foodModel.newSize.unit.abbreviation)
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
    
    var nameField: some View {
        let binding = Binding<String>(
            get: { foodModel.newSize.name },
            set: { newValue in
                foodModel.newSize.name = newValue.lowercased()
            }
        )

        return TextField("name", text: binding)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 12)
            .frame(minWidth: 44)
            .background(background)
    }

    var multiplySymbol: some View {
        symbol("×")
    }

    func symbol(_ string: String) -> some View {
        Text(string)
            .font(.title3)
            .foregroundStyle(Color(.tertiaryLabel))
    }

    var background: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(Color(.tertiarySystemFill))
    }
}
