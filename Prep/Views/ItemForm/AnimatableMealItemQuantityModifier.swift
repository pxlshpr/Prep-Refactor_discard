import SwiftUI

struct AnimatableMealItemQuantityModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    var value: Double
    var unitString: String
    var isAnimating: Bool
    
    let fontSize: CGFloat = 28
    let fontWeight: Font.Weight = .medium
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var uiFont: UIFont {
        UIFont.systemFont(ofSize: fontSize, weight: fontWeight.uiFontWeight)
    }
    
    var size: CGSize {
        uiFont.fontSize(for: value.formattedNutrient)
    }
    
    let unitFontSize: CGFloat = 17
    let unitFontWeight: Font.Weight = .semibold
    
    var unitUIFont: UIFont {
        UIFont.systemFont(ofSize: unitFontSize, weight: unitFontWeight.uiFontWeight)
    }
    
    var unitWidth: CGFloat {
        unitUIFont.fontSize(for: unitString).width
    }
    
    var amountString: String {
        if isAnimating {
            return value.formattedMealItemAmount
        } else {
            return value.cleanAmount
        }
    }
    
    func body(content: Content) -> some View {
        content
//            .frame(width: size.width, height: size.height)
//            .frame(width: 200 + unitWidth, height: size.height)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .overlay(
                HStack {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text(amountString)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(Color(.label))
                            .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
                        Text(unitString)
                            .font(.system(size: unitFontSize, weight: unitFontWeight, design: .rounded))
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .bold()
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color(.systemFill).opacity(0.5))
                    )
                    .hoverEffect(.highlight)

                }
            )
    }
}

extension View {
    func animatedMealItemQuantity(value: Double, unitString: String, isAnimating: Bool) -> some View {
        modifier(AnimatableMealItemQuantityModifier(value: value, unitString: unitString, isAnimating: isAnimating))
    }
}
