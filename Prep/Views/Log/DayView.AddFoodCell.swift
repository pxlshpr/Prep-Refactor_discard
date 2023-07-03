import SwiftUI
import Charts

import SwiftHaptics
import ViewSugar
import FoodDataTypes

extension DayView {
    
    struct AddFoodCell: View {
    
        @Environment(\.colorScheme) var colorScheme
        
        let meal: Meal2
        @Binding var leadingPadding: CGFloat
        @Binding var trailingPadding: CGFloat
        
        @State var showingFoodPicker = false
    }
}

extension DayView.AddFoodCell {
    var body: some View {
        Button {
            Haptics.selectionFeedback()
            showingFoodPicker = true
        } label: {
            label
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .hoverEffect(.highlight)
        
        .padding(.leading, leadingPadding)
        .padding(.trailing, trailingPadding)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
//        .sheet(isPresented: $showingFoodPicker) { foodPicker }
    }
    
    
    var label: some View {
        HStack {
            Image(systemName: "plus")
                .padding(5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(Color(.secondarySystemFill))
                )
                .padding(.leading, 5)
                .popover(isPresented: $showingFoodPicker) { foodPicker }
//                .fullScreenCover(isPresented: $showingFoodPicker) { foodPicker }
            Text("Add Food")
            Spacer()
            if !meal.foodItems.isEmpty {
                stats
            }
        }
    }
    
    var foodPicker: some View {
//        FoodPickerTest(
        FoodPicker(
            isPresented: $showingFoodPicker,
            meal: meal
        )
        .presentationCompactAdaptation(horizontal: .sheet, vertical: .popover)
//        .presentationDetents([.medium, .fraction(0.90)])
    }
    
    var stats: some View {
        Group {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                energyText
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(Color(.secondaryLabel))
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
    }
    
    var energyText: some View {
        let energy = meal.energy(in: .kcal)
        let string = NumberFormatter.energyValue.string(for: energy) ?? ""
        return Text("\(string)")
    }
}
