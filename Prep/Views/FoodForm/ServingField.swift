import SwiftUI
import OSLog

import SwiftHaptics

let foodFormLogger = Logger(subsystem: "FoodForm", category: "")

struct ServingField: View {
    
    @Environment(\.colorScheme) var colorScheme

    @State var showingUnitPicker = false

    var foodModel: FoodModel

    @State var showingNewSizeAlert: Bool = false
    @State var newSizeName: String = ""

    init(foodModel: FoodModel) {
        self.foodModel = foodModel
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text("Serving Size")
                .layoutPriority(1)
            Spacer()
            if foodModel.hasServing {
                textField
                unitPicker
                    .layoutPriority(1)
                removeButton
            } else {
                addButton
            }
        }
        .alert("Enter a name", isPresented: $showingNewSizeAlert) {
            TextField("Enter a name", text: $newSizeName)
            Button("OK", action: addNewSize)
        } message: {
            Text("Give this size a name.")
        }
    }
    
    var addButton: some View {
        Button("Add") {
            foodModel.servingValue = DefaultServingValue.amount
            foodModel.servingUnit = DefaultServingValue.unit
        }
    }
    
    var removeButton: some View {
        Button(role: .destructive) {
            foodModel.servingValue = nil
            foodModel.servingUnit = nil
        } label: {
            Image(systemName: "minus.circle")
        }
    }
    
    var textField: some View {
        let binding = Binding<Double>(
            get: {
                foodModel.servingValue ?? DefaultServingValue.amount
            },
            set: { newValue in
                foodModel.servingValue = newValue
                foodModel.setSaveDisabled()
            }
        )

        return TextField("", value: binding, formatter: NumberFormatter.foodValue)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .simultaneousGesture(textSelectionTapGesture)
    }
    
    var unitPicker: some View {
        
        let binding = Binding<FormUnit>(
            get: {
                foodModel.servingUnit ?? DefaultServingValue.unit
            },
            set: { newValue in
                withAnimation(.snappy) {
                    foodModel.servingUnit = newValue
                    foodModel.setSaveDisabled()
                }
            }
        )
        
        func button(_ formUnit: FormUnit) -> some View {
            Button {
                binding.wrappedValue = formUnit
            } label: {
                Text("\(formUnit.name) (\(formUnit.abbreviation))")
            }
        }
        
        var sizesSections: some View {
            Section("Sizes") {
                ForEach(foodModel.sizes.sorted(), id: \.self) { size in
                    if size.isVolumePrefixed {
                        Menu {
                            ForEach(VolumeUnitType.primaryUnits, id: \.self) { volumeUnit in
                                Button {
                                    binding.wrappedValue = .size(size, volumeUnit.defaultVolumeUnit)
                                } label: {
                                    Text("\(volumeUnit.name) (\(volumeUnit.abbreviation))")
                                }
                            }
                            Section("Others") {
                                ForEach(VolumeUnitType.secondaryUnits, id: \.self) { volumeUnit in
                                    Button {
                                        binding.wrappedValue = .size(size, volumeUnit.defaultVolumeUnit)
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
                            binding.wrappedValue = .size(size, nil)
                        } label: {
                            Text(size.name)
                        }
                    }
                }
            }
        }
        
        return Menu {
            Section {
                Menu {
                    ForEach(WeightUnit.allCases, id: \.self) { weightUnit in
                        button(.weight(weightUnit))
                    }
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
                Divider()
                Button {
                    showingNewSizeAlert = true
                } label: {
                    Text("New Size…")
                }
                Divider()
            }
            sizesSections
        } label: {
            HStack(spacing: 4) {
                Text(binding.wrappedValue.abbreviation)
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
    
    func addNewSize() {
        foodModel.addServingBasedSize(newSizeName)
        newSizeName = ""
    }
}
