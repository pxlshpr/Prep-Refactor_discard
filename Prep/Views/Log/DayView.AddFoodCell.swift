import SwiftUI
import Charts

import SwiftHaptics
import ViewSugar
import FoodDataTypes

extension DayView {
    
    struct AddFoodCell: View {
    
//        @Environment(\.colorScheme) var colorScheme
//        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        @Environment(\.verticalSizeClass) var verticalSizeClass

        let meal: Meal
//        @Binding var leadingPadding: CGFloat
        @Binding var trailingPadding: CGFloat
        
        @State var showingFoodPicker = false
        
        @State var safeAreaInsets: EdgeInsets = EdgeInsets()
        let safeAreaDidChange = NotificationCenter.default.publisher(for: .safeAreaDidChange)
    }
}

extension DayView.AddFoodCell {
    var body: some View {
        let _ = Self._printChanges()
        return Button {
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
        
        .onReceive(safeAreaDidChange, perform: safeAreaDidChange)
    }
    func safeAreaDidChange(notification: Notification) {
        guard let insets = notification.userInfo?[Notification.PrepKeys.safeArea] as? EdgeInsets else {
            fatalError()
        }
        self.safeAreaInsets = insets
    }
    
    var leadingPadding: CGFloat {
        verticalSizeClass == .compact
        ? safeAreaInsets.leading
        : 0
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
            Text("Add Food")
            Spacer()
            if !meal.foodItems.isEmpty {
                stats
            }
        }
    }
    
    var foodPicker: some View {
//        EmptyView()
//        FoodPicker()
        FoodPicker_Legacy(isPresented: $showingFoodPicker, meal: meal)
//        FoodPicker_Legacy(isPresented: $showingFoodPicker)
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
    
//    var macrosChart: some View {
//        Chart(meal.macrosChartData, id: \.macro) { macroValue in
//            SectorMark(
//                angle: .value("kcal", macroValue.kcal),
//                innerRadius: .ratio(0.5),
//                angularInset: 0.5
//            )
//            .cornerRadius(3)
//            .foregroundStyle(by: .value("Macro", macroValue.macro))
//        }
//        .chartForegroundStyleScale(Macro.chartStyleScale(colorScheme))
//        .chartLegend(.hidden)
//        .frame(width: 28, height: 28)
//    }
    
    var energyText: some View {
        let energy = meal.energy(in: .kcal)
        let string = NumberFormatter.energyValue.string(for: energy) ?? ""
        return Text("\(string)")
    }
}
