import SwiftUI

import FoodDataTypes

struct AnimatableItemEnergyModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    var value: Double
    var energyUnit: EnergyUnit
    var isAnimating: Bool
    
//    let fontSize: CGFloat = 28
//    let fontWeight: Font.Weight = .medium
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
//    var uiFont: UIFont {
//        UIFont.systemFont(ofSize: fontSize, weight: fontWeight.uiFontWeight)
//    }
//    
//    var size: CGSize {
//        uiFont.fontSize(for: value.formattedNutrient)
//    }
//    
//    let unitFontSize: CGFloat = 17
//    let unitFontWeight: Font.Weight = .semibold
//    
//    var unitUIFont: UIFont {
//        UIFont.systemFont(ofSize: unitFontSize, weight: unitFontWeight.uiFontWeight)
//    }
//    
//    var unitWidth: CGFloat {
//        unitUIFont.fontSize(for: unitString).width
//    }
    
    var amountString: String {
        if isAnimating {
            return value.formattedEnergy
        } else {
            return value.formattedEnergy
        }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
//            .frame(height: size.height)
            .frame(height: 44)
            .overlay(
                HStack {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text(amountString)
                            .multilineTextAlignment(.leading)
                            .font(.headline)
                            .foregroundStyle(Color(.label))
//                            .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
                        Text(energyUnit.abbreviation)
//                            .font(.system(size: unitFontSize, weight: unitFontWeight, design: .rounded))
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .bold()
                            .foregroundStyle(Color(.secondaryLabel))
                    }
//                    .padding(.vertical, 5)
//                    .padding(.horizontal, 10)
//                    .background(
//                        RoundedRectangle(cornerRadius: 7, style: .continuous)
//                            .fill(Color(.systemFill).opacity(0.5))
//                    )
//                    .hoverEffect(.highlight)

                }
            )
    }
}

extension View {
    func animatedItemEnergy(
        value: Double,
        energyUnit: EnergyUnit,
        isAnimating: Bool
    ) -> some View {
        modifier(AnimatableItemEnergyModifier(
            value: value,
            energyUnit: energyUnit,
            isAnimating: isAnimating
        ))
    }
}
