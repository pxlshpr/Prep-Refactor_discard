import SwiftUI

import FoodDataTypes

//MARK: - Item Energy

struct AnimatableItemEnergyModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    var value: Double
    var energyUnit: EnergyUnit
    var isAnimating: Bool
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var string: String {
        value.formattedNutrientValue
            .replacingLastOccurrence(of: "-", with: "")
    }
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .overlay(
                HStack {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text(string)
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

//MARK: - Item Macro

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
    
    var string: String {
        value.formattedNutrientValue
            .replacingLastOccurrence(of: "-", with: "")
    }
    
    var foregroundStyle: Color {
        isPrimary
        ? macro.textColor(for: colorScheme)
        : Color(.secondaryLabel)
    }
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .overlay(
                HStack {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text(string)
                            .multilineTextAlignment(.leading)
                            .font(.headline)
                        Text("g")
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(foregroundStyle)
                    .fontWeight(.regular)
//                    .bold(isPrimary)
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

//MARK: - Meal Energy

struct AnimatableMealEnergyModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    var value: Double
    var energyUnit: EnergyUnit
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var amountString: String {
        value.formattedNutrientValue
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
                            .font(.footnote)
                            .monospacedDigit()
                            .foregroundStyle(Color(.secondaryLabel))
                        Text(energyUnit.abbreviation)
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.caption2)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            )
    }
}

extension View {
    func animatedMealEnergy(
        value: Double,
        energyUnit: EnergyUnit
    ) -> some View {
        modifier(AnimatableMealEnergyModifier(
            value: value,
            energyUnit: energyUnit
        ))
    }
}

//MARK: - Item Micro

struct AnimatableItemMicroModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    var value: Double
    var micro: Micro
    var unit: NutrientUnit
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var string: String {
        value.formattedNutrientValue
            .replacingLastOccurrence(of: "-", with: "")
    }
    
    var foregroundStyle: Color {
        Color(.secondaryLabel)
    }
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .overlay(
                HStack {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text(string)
                            .multilineTextAlignment(.leading)
                            .font(.headline)
                        Text(unit.abbreviation)
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(foregroundStyle)
                    .fontWeight(.regular)
                }
            )
    }
}

extension View {
    func animatedItemMicro(
        value: Double,
        micro: Micro,
        unit: NutrientUnit
    ) -> some View {
        modifier(AnimatableItemMicroModifier(
            value: value,
            micro: micro,
            unit: unit
        ))
    }
}
