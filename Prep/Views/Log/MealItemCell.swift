import SwiftUI
import OSLog

import SwiftHaptics
import ViewSugar
import FoodLabel

private let logger = Logger(subsystem: "MealItemCell", category: "")

private var lastWidth: CGFloat = 0

struct MealItemCell: View {
    
    @Environment(\.colorScheme) var colorScheme

    let item: FoodItem
    let meal: Meal

    @State var width: CGFloat
    
    @State var showingItemForm = false
    
    init(item: FoodItem, meal: Meal) {
        self.item = item
        self.meal = meal
        
        /// Always reuse whatever the last saved width was as the start point.
        /// This it to mitigate a bug where newly added food items don't get their width set
        /// by `readSize`, and therefore get a badge width of `0` assigned until a proper
        /// view refresh. This only happens when re-inserting a food item that was just deleted.
        _width = State(initialValue: lastWidth)
    }
    
    var body: some View {
        Button {
            Haptics.selectionFeedback()
            showingItemForm = true
        } label: {
            label
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .hoverEffect(.highlight)
                .readSize {
                    lastWidth = $0.width
                    self.width = $0.width
                }
        }
        .contextMenu(menuItems: { menuItems }, preview: {
            FoodLabel(data: .constant(item.foodLabelData))
        })
    }

    var menuItems: some View {
        Section(item.food.name) {
            Button {
                
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Task.detached(priority: .high) {
                    guard let updatedDay = await FoodItemsStore.delete(item) else {
                        return
                    }
                    await MainActor.run {
                        post(.didDeleteFoodItem, userInfo: [.day: updatedDay])
                    }
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
            isPresented: $showingItemForm,
            foodItem: item,
            meal: meal
        )
    }
    
    var foodBadge: some View {
        let widthBinding = Binding<CGFloat>(
            get: {
                let max = width * 0.25
                return (item.energy * max) / item.largestEnergyInKcal
            },
            set: { _ in }
        )

        return Group {
//            if UserManager.showingLogBadgesForFoods {
            FoodBadge(food: item.food, width: widthBinding)
//                .opacity(model.hasPassed ? 0.7 : 1)
//                .opacity(item.energyInKcal == 0 ? 0 : 1)
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
                Text(item.food.emoji)
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
        Text(item.quantityDescription)
            .font(.callout)
            .fontWeight(.regular)
            .foregroundStyle(Color(.secondaryLabel))
    }
    
    func nameTexts(withAmount: Bool) -> some View {
        var view = Text(item.food.name)
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(nameColor)
//        if model.showingFoodDetails {
            if let detail = item.food.detail, !detail.isEmpty {
                view = view
                + Text(", ")
                    .font(.callout)
                    .foregroundStyle(Color(.secondaryLabel))
                + Text(detail)
                    .font(.callout)
                    .foregroundStyle(Color(.secondaryLabel))
            }
            if let brand = item.food.brand, !brand.isEmpty {
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
