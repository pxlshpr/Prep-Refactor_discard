import SwiftUI
import Charts

import SwiftHaptics
import ViewSugar
import FoodDataTypes

struct MealFooter: View {

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.colorScheme) var colorScheme

    @State var meal: Meal
    
    @State var showingFoodPicker = false
    
    @State var safeAreaInsets: EdgeInsets
    let safeAreaDidChange = NotificationCenter.default.publisher(for: .safeAreaDidChange)
    let didAddFoodItem = NotificationCenter.default.publisher(for: .didAddFoodItem)
    let didDeleteFoodItem = NotificationCenter.default.publisher(for: .didDeleteFoodItem)

    init(meal: Meal) {
        _meal = State(initialValue: meal)
        _safeAreaInsets = State(initialValue: currentSafeAreaInsets)
    }
    
    var body: some View {
        content
            .onReceive(safeAreaDidChange, perform: safeAreaDidChange)
            .onReceive(didAddFoodItem, perform: didUpdateDay)
            .onReceive(didDeleteFoodItem, perform: didUpdateDay)
    }
    
    var content: some View {
        HStack {
            addFoodButton
                .popover(isPresented: $showingFoodPicker) { foodPicker }
            Spacer()
            if !meal.foodItems.isEmpty {
                stats
            }
        }
        .padding(.horizontal, 8)
//        .padding(.vertical, 12)
        
        .padding(.leading, leadingPadding)
        .padding(.trailing, trailingPadding)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden, edges: .bottom)
    }

    var addFoodButton: some View {
        var label: some View {
            Text("Add Food")
                .font(.caption)
                .bold()
                .foregroundStyle(.accent)
                .padding(.horizontal, 8)
                .frame(height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor.opacity(
                            colorScheme == .dark ? 0.1 : 0.15
                        ))
                )
                .frame(maxHeight: .infinity)
                .padding(.leading, 10)
        }

        var button: some View {
            return Button {
                tapped()
            } label: {
                label
            }
        }
        
        return button
            .onTapGesture { tapped() }
            .contentShape(Rectangle())
            .padding(.trailing)
            .buttonStyle(.borderless)
    }
    
    func tapped() {
        Haptics.selectionFeedback()
        showingFoodPicker = true
    }
    
    var legacyButton: some View {
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
    }
    
    func didUpdateDay(notification: Notification) {
        /// Only interested when the updated day was what this meal belonged to
        guard let userInfo = notification.userInfo,
              let day = userInfo[Notification.PrepKeys.day] as? Day,
              let updatedMeal = day.meal(with: self.meal.id)
        else {
            return
        }
        
        /// Wait a bit for the form to dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.snappy) {
                self.meal = updatedMeal
            }
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

    var foodPicker: some View {
        FoodPicker(meal: meal) { _ in
            showingFoodPicker = false
        }
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
