import SwiftUI
import OSLog

import SwiftHaptics

struct MealView: View {

    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @State var meal: Meal

    let title: String
    @State var foodItems: [FoodItem]
    
    @State var safeAreaInsets: EdgeInsets
    
    let safeAreaDidChange = NotificationCenter.default.publisher(for: .safeAreaDidChange)
    let didAddFoodItem = NotificationCenter.default.publisher(for: .didAddFoodItem)
    
    init(meal: Meal) {
        _meal = State(initialValue: meal)
        self.title = meal.title
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
            addFoodCell
        }
        .onReceive(didAddFoodItem, perform: didAddFoodItem)
        .onReceive(safeAreaDidChange, perform: safeAreaDidChange)
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
                    SoundPlayer.play(.octaveTapSimple)
                    self.foodItems.append(foodItem)
//                } else {
                }
                self.foodItems = updatedMeal.foodItems
                self.meal = updatedMeal
            }
        }
    }
    
    func cell(foodItem: FoodItem) -> some View {
        Button {
            Haptics.selectionFeedback()
//            model.foodItemBeingEdited = foodItem
//            showingItemForm = true
        } label: {
            MealItemCell(item: foodItem)
        }
    }

    var header: some View {
        Menu {
            Button(role: .destructive) {
                Haptics.successFeedback()
                
//                do {
//                    let logger = Logger(subsystem: "MealView", category: "delete")
//                    let id = meal.id
//                    let descriptor = FetchDescriptor<MealEntity>(predicate: #Predicate {
//                        $0.uuid == id
//                    })
//                    logger.debug("Fetching meal to delete: \(id, privacy: .public)")
//                    guard let meal = try context.fetch(descriptor).first else {
//                        logger.error("Could not find meal")
//                        return
//                    }
//                    logger.debug("Deleting meal: \(id, privacy: .public)")
//                    context.delete(meal)
//                    
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        Task {
//                            logger.debug("Saving context")
//                            try context.save()
//                        }
//                    }
//                } catch {
//                    /// Getting configuration error when trying to delete a meal that can't be found
//                    fatalError(error.localizedDescription)
//                }
//
//                post(.didDeleteMeal, userInfo: [.meal: meal])

//                MealStore.delete(meal)
                
            } label: {
                Label("Delete", systemImage: "trash")
                    .textCase(.none)
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(Color(.secondaryLabel))
                    .font(.system(.callout, design: .rounded, weight: .light))
                    .textCase(.none)
                Image(systemName: "chevron.down.circle.fill")
                    .symbolRenderingMode(.palette)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.secondaryLabel), Color(.secondarySystemFill))
                    .imageScale(.small)
            }
        }
        .padding(.leading, leadingPadding)
        .padding(.trailing, trailingPadding)
        .frame(height: 25)
    }
    
    var addFoodCell: some View {
        MealAddFoodCell(meal: meal)
    }
}
