import SwiftUI

import FoodDataTypes

struct AnimatableItemEnergyModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    var value: Double
    var energyUnit: EnergyUnit
    var isAnimating: Bool
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var amountString: String {
        if isAnimating {
            return value.formattedNutrientValue
        } else {
            return value.formattedNutrientValue
        }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .overlay(
                HStack {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text(amountString)
                            .multilineTextAlignment(.leading)
                        Text(energyUnit.abbreviation)
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.headline)
                    .foregroundStyle(Color(.label))
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

struct AnimatableItemMacroModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    var value: Double
    var macro: Macro
    var isPrimary: Bool
    var isAnimating: Bool
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var amountString: String {
        if isAnimating {
            return value.formattedNutrientValue
        } else {
            return value.formattedNutrientValue
        }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .overlay(
                HStack {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text(amountString)
                            .multilineTextAlignment(.leading)
                            .font(.headline)
                        Text("g")
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(macro.textColor(for: colorScheme))
                    .bold(isPrimary)
                }
            )
    }
}

extension View {
    func animatedItemMacro(
        value: Double,
        macro: Macro,
        isPrimary: Bool,
        isAnimating: Bool
    ) -> some View {
        modifier(AnimatableItemMacroModifier(
            value: value,
            macro: macro,
            isPrimary: isPrimary,
            isAnimating: isAnimating
        ))
    }
}