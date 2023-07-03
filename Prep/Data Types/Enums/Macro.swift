import SwiftUI
import ColorSugar
import FoodDataTypes

extension Macro {
    
    func fillColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .carb:
            return colorScheme == .light
            ? Color(hex: "FFB02A")
            : Color(hex: "FFCD34")
        case .fat:
            return colorScheme == .light
            ? Color(hex: "B900FF")
            : Color(hex: "DF00FF")
        case .protein:
            return colorScheme == .light
            ? Color(hex: "47ACB1")
            : Color(hex: "47ACB1")
        }
    }
    
    func textColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .carb:
            return colorScheme == .light
            ? Color(hex: "CA7700")
            : Color(hex: "FFCD34")
        case .fat:
            return colorScheme == .light
            ? Color(hex: "B900FF")
            : Color(hex: "E742FF")
        case .protein:
            return colorScheme == .light
            ? Color(hex: "3D969A")
            : Color(hex: "9AFBFF")
        }
    }
}

import Charts

extension Macro: Plottable {
    
    var kcalsPerGram: Double {
        switch self {
        case .carb:     KcalsPerGramOfCarb
        case .fat:      KcalsPerGramOfFat
        case .protein:  KcalsPerGramOfProtein
        }

    }
    static func chartStyleScale(_ colorScheme: ColorScheme) -> KeyValuePairs<Macro, Color> {
        KeyValuePairs(dictionaryLiteral:
                        (Macro.carb, Macro.carb.fillColor(for: colorScheme)),
                        (Macro.fat, Macro.fat.fillColor(for: colorScheme)),
                        (Macro.protein, Macro.protein.fillColor(for: colorScheme))
        )
    }
}


