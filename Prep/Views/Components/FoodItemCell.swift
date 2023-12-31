import SwiftUI
import OSLog

import SwiftHaptics
import ViewSugar
import FoodLabel

private let logger = Logger(subsystem: "FoodItemCell", category: "")

private var lastWidth: CGFloat = 0
private var lastFoodItemWidth: CGFloat = 0

struct FoodItemCell: View {
    
    @Environment(\.colorScheme) var colorScheme

    let foodItem: FoodItem
    let meal: Meal?

    @State var width: CGFloat
    
    @State var showingItemForm = false
    
    let handleDelete: ((FoodItem) -> ())?
    
    init(
        _ foodItem: FoodItem,
        meal: Meal? = nil,
        handleDelete: ((FoodItem) -> ())? = nil
    ) {
        self.foodItem = foodItem
        self.meal = meal
        self.handleDelete = handleDelete
        
        /// Always reuse whatever the last saved width was as the start point.
        /// This it to mitigate a bug where newly added food items don't get their width set
        /// by `readSize`, and therefore get a badge width of `0` assigned until a proper
        /// view refresh. This only happens when re-inserting a food item that was just deleted.
        let width: CGFloat = if meal == nil {
            lastFoodItemWidth
        } else {
            lastWidth
        }
        _width = State(initialValue: width)
    }
    
    var body: some View {
        Button {
            showEditForm()
        } label: {
            label
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .hoverEffect(.highlight)
                .readSize {
                    if meal == nil {
                        lastFoodItemWidth = $0.width
                    } else {
                        lastWidth = $0.width
                    }
                    self.width = $0.width
                }
        }
        .contextMenu(menuItems: { menuItems }, preview: {
            FoodLabel(data: .constant(foodItem.foodLabelData))
        })
    }
    
    var isMealItem: Bool {
        meal != nil
    }
    
    func showEditForm() {
        Haptics.selectionFeedback()
        showingItemForm = true
    }

    var menuItems: some View {
        Section(foodItem.food.name) {
            Button {
                showEditForm()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                if isMealItem {
                    Task.detached(priority: .high) {
                        guard let updatedDay = await FoodItemsStore.delete(foodItem) else {
                            return
                        }
                        await MainActor.run {
                            post(.didDeleteFoodItem, userInfo: [.day: updatedDay])
                        }
                    }
                } else {
                    handleDelete?(foodItem)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    var label: some View {
        HStack(spacing: 0) {
            optionalEmojiText
            nameTexts(withAmount: true)
            Spacer()
            foodBadge
        }
        .popover(isPresented: $showingItemForm, attachmentAnchor: CellPopoverAnchor) {
            itemForm
        }
    }
    
    var itemForm: some View {
        ItemForm(
            foodItem: foodItem,
            meal: meal
        ) { _ in
            showingItemForm = false
        }
    }
    
    var foodBadge: some View {
        let widthBinding = Binding<CGFloat>(
            get: {
                guard foodItem.largestEnergyInKcal > 0 else { return 0 }
                let max = width * 0.25
                return (foodItem.energy * max) / foodItem.largestEnergyInKcal
            },
            set: { _ in }
        )

        return Group {
//            if UserManager.showingLogBadgesForFoods {
            FoodBadge(food: foodItem.food, width: widthBinding)
//                .opacity(model.hasPassed ? 0.7 : 1)
//                .opacity(foodItem.energyInKcal == 0 ? 0 : 1)
                .transition(.scale)
                .padding(.trailing, 10)
//            }
        }
    }
    
    var optionalEmojiText: some View {
        
        var opacity: CGFloat {
            1
//            model.hasPassed ? 0.7 : 1
        }

        return Group {
//            if model.showingEmojis {
                Text(foodItem.food.emoji)
                .font(.body)
                    .opacity(opacity)
                    .padding(.leading, 5)
//            }
        }
    }
    
    var nameColor: Color {
//        model.hasPassed
//        ? Color(.secondaryLabel)
//        : Color(.label)
        Color(.label)
    }
    
    var amountText: Text {
        Text(foodItem.quantityDescription)
            .font(.callout)
            .fontWeight(.regular)
            .foregroundStyle(Color(.secondaryLabel))
    }
    
    func nameTexts(withAmount: Bool) -> some View {
        var view = Text(foodItem.food.name)
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(nameColor)
//        if model.showingFoodDetails {
            if let detail = foodItem.food.detail, !detail.isEmpty {
                view = view
                + Text(", ")
                    .font(.callout)
                    .foregroundStyle(Color(.secondaryLabel))
                + Text(detail)
                    .font(.callout)
                    .foregroundStyle(Color(.secondaryLabel))
            }
            if let brand = foodItem.food.brand, !brand.isEmpty {
                view = view
                + Text(", ")
                    .font(.callout)
                    .foregroundStyle(Color(.tertiaryLabel))
                + Text(brand)
                    .font(.callout)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
//        }
        
        if withAmount {
            view = view
            + Text(" • ").foregroundStyle(Color(.secondaryLabel))
            + amountText

        }
        
        return view
            .multilineTextAlignment(.leading)
//            .padding(.leading, model.showingEmojis ? 8 : 10)
            .padding(.leading, 8)
            .fixedSize(horizontal: false, vertical: true)
    }
}
