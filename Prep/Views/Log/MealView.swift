import SwiftUI
import OSLog

import SwiftHaptics
import FoodLabel

struct MealView: View {

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.colorScheme) var colorScheme

    @State var meal: Meal
    @State var foodItems: [FoodItem]
    
    @State var safeAreaInsets: EdgeInsets
    
    @State var showingMealForm = false
    @State var showingFoodPicker = false

    let safeAreaDidChange = NotificationCenter.default.publisher(for: .safeAreaDidChange)
    let didAddFoodItem = NotificationCenter.default.publisher(for: .didAddFoodItem)
    let didDeleteFoodItem = NotificationCenter.default.publisher(for: .didDeleteFoodItem)
    let didModifyMeal = NotificationCenter.default.publisher(for: .didModifyMeal)

    init(meal: Meal) {
        _meal = State(initialValue: meal)
        _foodItems = State(initialValue: meal.foodItems)

        _safeAreaInsets = State(initialValue: currentSafeAreaInsets)
    }
    
    var body: some View {
        Section(header: header) {
            ForEach(foodItems) { foodItem in
                cell(foodItem: foodItem)
                    .padding(.leading, leadingPadding)
                    .padding(.trailing, trailingPadding)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            if foodItems.isEmpty {
                emptyCell
            }
            footer
        }
        .onReceive(didAddFoodItem, perform: didAddFoodItem)
        .onReceive(didDeleteFoodItem, perform: didDeleteFoodItem)
        .onReceive(safeAreaDidChange, perform: safeAreaDidChange)
        .onReceive(didModifyMeal, perform: didModifyMeal)
    }

    var emptyCell: some View {
        var label: some View {
            Text("Empty")
                .font(.body)
                .fontWeight(.light)
                .foregroundStyle(Color(.tertiaryLabel))
                .frame(maxWidth: .infinity, alignment: .leading)
            
                .padding(.leading, 5)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .hoverEffect(.highlight)
        }
        
        var button: some View {
            Button {
                Haptics.selectionFeedback()
                showingFoodPicker = true
            } label: {
                label
            }
            .popover(isPresented: $showingFoodPicker, attachmentAnchor: CellPopoverAnchor) {
                foodPicker
            }
        }
        
        return button
            .padding(.leading, leadingPadding)
            .padding(.trailing, trailingPadding)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    var foodPicker: some View {
//        FoodPicker(isPresented: $showingFoodPicker, meal: meal)
        FoodPicker(meal: meal) { _ in
            showingFoodPicker = false
        }
    }

    func didModifyMeal(notification: Notification) {
        DispatchQueue.main.async {
            guard
                let info = notification.userInfo,
                let day = info[Notification.PrepKeys.day] as? Day,
                day.date == self.meal.date,
                let updatedMeal = day.meal(with: self.meal.id)
            else { return }
            withAnimation(.snappy) {
                self.meal = updatedMeal
                self.foodItems = updatedMeal.foodItems
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
//        0
    }

    var trailingPadding: CGFloat {
        verticalSizeClass == .compact ? safeAreaInsets.trailing : 0
    }

    func didAddFoodItem(_ notification: Notification) {
        /// Only interested when the food item was added to a day that this meal belongs to
        guard let userInfo = notification.userInfo,
              let day = userInfo[Notification.PrepKeys.day] as? Day,
              let foodItem = userInfo[Notification.PrepKeys.foodItem] as? FoodItem,
              let updatedMeal = day.meal(with: self.meal.id)
        else {
            return
        }
        
        /// Wait a bit for the form to dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.snappy) {
                /// If the added food item belongs to this meal, insert it with an animation and play a sound
                if foodItem.mealID == meal.id {
//                    SoundPlayer.play(.octaveTapSimple)
                    /// Not needed so we removed this potentially duplicate animation (with setting the food items below)
//                    self.foodItems.append(foodItem)
                }
                
                self.foodItems = updatedMeal.foodItems
                self.meal = updatedMeal
            }
        }
    }
    
    func didDeleteFoodItem(_ notification: Notification) {
        /// Only interested when the food item was added to a day that this meal belongs to
        guard let userInfo = notification.userInfo,
              let day = userInfo[Notification.PrepKeys.day] as? Day,
              day.contains(meal: meal),
              let updatedMeal = day.meal(with: self.meal.id)
        else {
            return
        }
        
        /// Wait a bit for the form to dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.snappy) {
                self.meal = updatedMeal
                self.foodItems = updatedMeal.foodItems
            }
        }
    }
    
    func cell(foodItem: FoodItem) -> some View {
        FoodItemCell(foodItem, meal: meal)
//        @ViewBuilder
//        var menuItems: some View {
//            Section(foodItem.food.name) {
//                Button {
//                    
//                } label: {
//                    Label("Edit", systemImage: "pencil")
//                }
//                Button(role: .destructive) {
//                    Task.detached(priority: .high) {
//                        guard let updatedDay = await FoodItemsStore.delete(foodItem) else {
//                            return
//                        }
//                        await MainActor.run {
//                            post(.didDeleteFoodItem, userInfo: [.day: updatedDay])
//                        }
//                    }
//                } label: {
//                    Label("Delete", systemImage: "trash")
//                }
//            }
//        }
//        
//        return Button {
//            tapped(foodItem)
//        } label: {
//            FoodItemCell(
//                item: foodItem,
//                meal: meal
//            )
//        }
//        .contextMenu(menuItems: { menuItems }, preview: {
//            FoodLabel(data: .constant(foodItem.foodLabelData))
//        })
    }

    var header: some View {
        
        var label: some View {
            HStack {
                Text("**\(meal.timeString)**")
                Text("•")
                Text(meal.name)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .textCase(.uppercase)
            .font(.footnote)
            .foregroundStyle(Color(.secondaryLabel))
        }
        
        return Button {
            Haptics.selectionFeedback()
            showingMealForm = true
        } label: {
            label
        }
        .padding(.leading, leadingPadding)
        .padding(.trailing, trailingPadding)
        .frame(height: 25)
        .popover(isPresented: $showingMealForm) { mealForm }
    }
    
    var mealForm: some View {
        MealForm(meal)
    }
    
    var footer: some View {
        MealFooter(meal: meal)
    }
}

extension MealView {
    
//    func tapped(_ foodItem: FoodItem) {
//        Haptics.selectionFeedback()
//        model.foodItemBeingEdited = foodItem
//        showingItemForm = true
//    }
    
    func tappedDeleteMeal() {
        Haptics.successFeedback()
//
//        do {
//            let logger = Logger(subsystem: "MealView", category: "delete")
//            let id = meal.id
//            let descriptor = FetchDescriptor<MealEntity>(predicate: #Predicate {
//                $0.uuid == id
//            })
//            logger.debug("Fetching meal to delete: \(id, privacy: .public)")
//            guard let meal = try context.fetch(descriptor).first else {
//                logger.error("Could not find meal")
//                return
//            }
//            logger.debug("Deleting meal: \(id, privacy: .public)")
//            context.delete(meal)
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                Task {
//                    logger.debug("Saving context")
//                    try context.save()
//                }
//            }
//        } catch {
//            /// Getting configuration error when trying to delete a meal that can't be found
//            fatalError(error.localizedDescription)
//        }
//
//        post(.didDeleteMeal, userInfo: [.meal: meal])
//
//        MealStore.delete(meal)
    }
}
