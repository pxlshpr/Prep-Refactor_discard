import SwiftUI
import OSLog

import SwiftHaptics

struct AmountField: View {
    
    @Environment(\.colorScheme) var colorScheme

    @State var showingUnitPicker = false

    var foodModel: FoodModel

    init(foodModel: FoodModel) {
        self.foodModel = foodModel
    }
    
    var title: String {
        "Nutrients Per"
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
            get: { foodModel.amountValue },
            set: { newValue in
                foodModel.amountValue = newValue
                foodModel.setSaveDisabled()
            }
        )

        return TextField("Required", value: binding, formatter: NumberFormatter.foodValue)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .simultaneousGesture(textSelectionTapGesture)
    }
    
    var unitPicker: some View {
        
        let binding = Binding<FormUnit>(
            get: { foodModel.amountUnit },
            set: { newValue in
                withAnimation(.snappy) {
                    foodModel.setAmountUnit(newValue)
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
                Button {
                    binding.wrappedValue = .serving
                } label: {
                    Text("Serving")
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

