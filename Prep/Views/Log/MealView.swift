import SwiftUI
import OSLog

import SwiftHaptics

struct MealView: View {

    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let meal: Meal

    let title: String
    @State var foodItems: [FoodItem]
    
    @State var safeAreaInsets: EdgeInsets
    
    let safeAreaDidChange = NotificationCenter.default.publisher(for: .safeAreaDidChange)
    let didAddFoodItem = NotificationCenter.default.publisher(for: .didAddFoodItem)
    
    init(meal: Meal) {
        self.meal = meal
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
            addFoodCell(meal)
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
        guard let foodItem = notification.userInfo?[Notification.PrepKeys.foodItem] as? FoodItem,
              foodItem.mealID == meal.id
        else {
            return
        }
        SoundPlayer.play(.octaveTapSimple)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.snappy) {
                self.foodItems.append(foodItem)
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
    
    func addFoodCell(_ meal: Meal) -> some View {
        MealAddFoodCell(meal: meal)
    }
}
