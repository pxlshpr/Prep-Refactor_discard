import SwiftUI

import SwiftHaptics
import ViewSugar

struct MealItemCell: View {
    
    @Environment(\.colorScheme) var colorScheme

    let item: FoodItem
    
    @State var width: CGFloat = 0
    var body: some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .hoverEffect(.highlight)
            .readSize {
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
                    print("Returning 0")
                    return 0
                }
                
                /// Otherwise have a base value that we append to the calculated one so that we have something visible for the smallest value
                let base = width * 0.0095
                let maxWithoutBase = width * 0.25
                let calculated = CGFloat(item.relativeEnergy * maxWithoutBase)
                let width = calculated + base
                print("Returning \(width)")
                return width
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
