import SwiftUI
import Charts

import SwiftHaptics
import ViewSugar
import FoodDataTypes

struct MealAddFoodCell: View {

    @Environment(\.verticalSizeClass) var verticalSizeClass

    @State var meal: Meal
    
    @State var showingFoodPicker = false
    
    @State var safeAreaInsets: EdgeInsets
    let safeAreaDidChange = NotificationCenter.default.publisher(for: .safeAreaDidChange)
    let didUpdateMeal = NotificationCenter.default.publisher(for: .didUpdateMeal)

    init(meal: Meal) {
        _meal = State(initialValue: meal)
        _safeAreaInsets = State(initialValue: currentSafeAreaInsets)
    }
    
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
        
        .onReceive(safeAreaDidChange, perform: safeAreaDidChange)
        .onReceive(didUpdateMeal, perform: didUpdateMeal)
    }
    
    func didUpdateMeal(notification: Notification) {
        guard let meal = notification.userInfo?[Notification.PrepKeys.meal] as? Meal,
              self.meal.id == meal.id
        else {
            return
        }
        withAnimation(.snappy) {
            self.meal = meal
        }
    }
    
    func safeAreaDidChange(notification: Notification) {
        guard let insets = notification.userInfo?[Notification.PrepKeys.safeArea] as? EdgeInsets else {
            fatalError()
        }
        self.safeAreaInsets = insets
    }
    
    var leadingPadding: CGFloat {
        verticalSizeClass == .compact ? safeAreaInsets.leading : 0
    }

    var trailingPadding: CGFloat {
        verticalSizeClass == .compact ? safeAreaInsets.trailing : 0
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
        FoodPicker(isPresented: $showingFoodPicker, meal: meal)
    }
    
    var stats: some View {
        Color.clear
            .animatedMealEnergy(
                value: meal.energy(in: .kcal),
                energyUnit: .kcal
            )
//        Group {
//            HStack(alignment: .firstTextBaseline, spacing: 4) {
//                energyText
//                    .font(.footnote)
//                    .monospacedDigit()
//                    .foregroundStyle(Color(.secondaryLabel))
//                Text("kcal")
//                    .font(.caption2)
//                    .foregroundStyle(Color(.tertiaryLabel))
//            }
//        }
    }
    
    var energyText: some View {
        let energy = meal.energy(in: .kcal)
        let string = NumberFormatter.energyValue.string(for: energy) ?? ""
        return Text("\(string)")
    }
}
