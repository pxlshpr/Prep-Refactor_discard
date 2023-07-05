import SwiftUI

import SwiftHaptics
import ViewSugar

import OSLog

private let logger = Logger(subsystem: "MealItemCell", category: "")

private var lastWidth: CGFloat = 0

struct MealItemCell: View {
    
    @Environment(\.colorScheme) var colorScheme

    let item: FoodItem
    
    @State var width: CGFloat
    
    init(item: FoodItem) {
        self.item = item
        
        /// Always reuse whatever the last saved width was as the start point.
        /// This it to mitigate a bug where newly added food items don't get their width set
        /// by `readSize`, and therefore get a badge width of `0` assigned until a proper
        /// view refresh. This only happens when re-inserting a food item that was just deleted.
        _width = State(initialValue: lastWidth)
    }
    
    var body: some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .hoverEffect(.highlight)
            .readSize {
                lastWidth = $0.width
                self.width = $0.width
            }
    }

    var content: some View {
        HStack(spacing: 0) {
            optionalEmojiText
            nameTexts(withAmount: true)
            Spacer()
            foodBadge
        }
    }
    
    var foodBadge: some View {
        let widthBinding = Binding<CGFloat>(
            get: {
                /// Always return 0 for 0 energy items
                guard item.energy > 0 else {
                    return 0
                }
                
                /// Otherwise have a base value that we append to the calculated one so that we have something visible for the smallest value
                let base = width * 0.0095
                let maxWithoutBase = width * 0.25
                let calculated = CGFloat(item.relativeEnergy * maxWithoutBase)
                let calculatedWidth = calculated + base
                    
                /// This is crucial because of an edge cases where we keep getting minutely different values
                /// (differing at the 5+ decimal place), resulting in an infinite loop due to this 'changing'.
                let rounded = CGFloat(Int(calculatedWidth))
                
                return rounded
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
