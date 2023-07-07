import SwiftUI
import Combine
import OSLog

import SwiftHaptics
import FoodDataTypes

let saveDisabledLogger = Logger(subsystem: "FoodForm", category: "saveDisabled")

struct NutrientField: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(FoodModel.self) var foodModel: FoodModel

    @Binding var nutrientValue: NutrientValue
    
    init(_ nutrientValue: Binding<NutrientValue>) {
        _nutrientValue = nutrientValue
    }
    
    var nutrient: Nutrient {
        nutrientValue.nutrient
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(nutrient.description)
                .layoutPriority(1)
            Spacer()
            textField
            unitPicker
        }
    }
    
    var textField: some View {
        let binding = Binding<Double>(
            get: { nutrientValue.value },
            set: { newValue in
                withAnimation {
                    nutrientValue.value = newValue
                }
                /// Delay so it doesn't interfere with the pie-chart animation
//                foodModel.delayedSetSaveDisabled()
                foodModel.setSaveDisabled()

                if nutrientValue.isMacro {
//                    foodModel.delayedUpdateSmallPieChart()
                    foodModel.smallChartData = self.foodModel.macrosChartData
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.snappy) {
                            foodModel.largeChartData = foodModel.macrosChartData
                        }
                    }
                }
            }
        )

        var placeholder: String {
            nutrient.isMandatory ? "Required" : ""
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
        
        func unitText(_ string: String) -> some View {
            Text(string)
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
        }
        
        var unitPickerForEnergy: some View {
            unitPicker(for: nil)
        }
        
        func unitPicker(for micro: Micro?) -> some View {
            let binding = Binding<NutrientUnit>(
                get: { nutrientValue.unit },
                set: { newUnit in
                    withAnimation(.snappy) {
                        nutrientValue.unit = newUnit
                    }
                }
            )
            
            var label: some View {
                HStack(spacing: 4) {
                    Text(nutrientValue.unit.abbreviation)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .foregroundStyle(Color(.secondaryLabel))
            }
            
            var menu: some View {
                Menu {
                    Picker(selection: binding, label: EmptyView()) {
                        if let micro {
                            ForEach(micro.supportedNutrientUnits, id: \.self) {
                                Text($0.abbreviation).tag($0)
                            }
                        } else {
                            ForEach([NutrientUnit.kcal, NutrientUnit.kJ], id: \.self) {
                                Text($0.abbreviation).tag($0)
                            }
                        }
                    }
                } label: {
                    label
                }
                .padding(.leading, 5)
                .padding(.vertical, 3)
                .contentShape(Rectangle())
                .hoverEffect(.highlight)
            }
            
            return menu
        }
        
        return Group {
            
            if nutrient.isEnergy {
                unitPickerForEnergy
                
            } else if let micro = nutrient.micro {
                if micro.supportedFoodLabelUnits.count > 1 {
                    unitPicker(for: micro)
                } else {
                    unitText(micro.supportedFoodLabelUnits.first?.abbreviation ?? "g")
                }
                
            } else {
                unitText("g")
            }
        }
    }
}


var textSelectionTapGesture: some Gesture {
    TapGesture().onEnded {
        Haptics.selectionFeedback()
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(
                #selector(UIResponder.selectAll),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}
