import SwiftUI

struct AnimatableMacroValue: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero
    
    var value: Double
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .overlay(
                animatedLabel
                    .readSize { size in
                        self.size = size
                    }
            )
    }
    
    var string: String {
        value.formattedMacro
            .replacingLastOccurrence(of: "-", with: "")
    }
    
    var animatedLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(string)
                .font(.system(.title2, design: .rounded, weight: .medium))
            Text("g")
                .font(.system(.callout, design: .rounded, weight: .medium))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

extension View {
    func animatedMacroValue(value: Double) -> some View {
        modifier(AnimatableMacroValue(value: value))
    }
}

struct AnimatableEnergyValue: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero
    
    var value: Double
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .overlay(
                animatedLabel
                    .readSize { size in
                        self.size = size
                    }
            )
    }
    
    var string: String {
        value.formattedEnergy
            .replacingLastOccurrence(of: "-", with: "")
    }
    
    var animatedLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(string)
                .font(.system(.title, design: .rounded, weight: .semibold))
            Text("kcal")
                .font(.system(.title3, design: .rounded, weight: .regular))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

extension View {
    func animatedEnergyValue(value: Double) -> some View {
        modifier(AnimatableEnergyValue(value: value))
    }
}

struct AnimatableEnergyRemainingValue: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero
    
    var value: Double
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .overlay(
                animatedLabel
                    .readSize { size in
                        self.size = size
                    }
            )
    }
    
    var animatedLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value.formattedEnergy)
                .font(.system(.headline, design: .rounded, weight: .medium))
                .foregroundStyle(Color(.secondaryLabel))
            Text("kcal")
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

extension View {
    func animatedEnergyRemainingValue(value: Double) -> some View {
        modifier(AnimatableEnergyRemainingValue(value: value))
    }
}

import FoodDataTypes

extension Macro {
    var abbreviatedDescription: String {
        switch self {
        case .carb:
            return "Carbs"
        case .fat:
            return "Fats"
        case .protein:
            return "Protein"
        }
    }
}

extension Macro {
    var nutrientMeterComponent: NutrientMeterComponent {
        switch self {
        case .carb:     .macro(.carb)
        case .fat:      .macro(.fat)
        case .protein:  .macro(.protein)
        }
    }
}
