import SwiftUI

import SwiftHaptics

struct MealItemCell: View {
    
    @Environment(\.colorScheme) var colorScheme

    let item: FoodItem
    
    var body: some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .hoverEffect(.highlight)
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
            get: { CGFloat(item.relativeEnergy * 140) },
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
