import SwiftUI

import SwiftHaptics
import OSLog

let foodFormLogger = Logger(subsystem: "FoodForm", category: "")

struct ServingField: View {
    
    @Environment(\.colorScheme) var colorScheme

    @State var showingUnitPicker = false

    let isServing: Bool
    var foodModel: FoodModel

    init(isServing: Bool = false, foodModel: FoodModel) {
        self.foodModel = foodModel
        self.isServing = isServing
    }
    
    var title: String {
        isServing ? "Serving Size" : "Nutrients Per"
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .layoutPriority(1)
            Spacer()
            textField
            unitPicker
                .layoutPriority(1)
        }
    }
    
    var textField: some View {
        let binding = Binding<Double>(
            get: {
                isServing
                ? foodModel.servingValue
                : foodModel.amountValue
            },
            set: { newValue in
                if isServing {
                    foodModel.servingValue = newValue
                } else {
                    foodModel.amountValue = newValue
                }
                foodModel.setSaveDisabled()
            }
        )

        var placeholder: String {
            isServing ? "" : "Required"
        }
        
        var tapGesture: some Gesture {
            textSelectionTapGesture
        }
        
        return TextField(placeholder, value: binding, formatter: NumberFormatter.foodValue)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .simultaneousGesture(tapGesture)
    }
    
    var unitPicker: some View {
        
        let binding = Binding<FormUnit>(
            get: {
                isServing
                ? foodModel.servingUnit
                : foodModel.amountUnit
            },
            set: { newValue in
                withAnimation(.snappy) {
                    if isServing {
                        foodModel.servingUnit = newValue
                    } else {
                        foodModel.setAmountUnit(newValue)
                    }
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
                if !isServing {
                    Button {
                        binding.wrappedValue = .serving
                    } label: {
                        Text("Serving")
                    }
                }
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
}

