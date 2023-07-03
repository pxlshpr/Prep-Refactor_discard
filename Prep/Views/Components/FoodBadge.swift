import SwiftUI

import FoodDataTypes

struct FoodBadge: View {

    static let DefaultWidth: CGFloat = 30

    @Environment(\.colorScheme) var colorScheme
    
    let carb, fat, protein: Double
    @Binding var width: CGFloat

//    init(_ searchResult: FoodResult) {
//        self.carb = searchResult.carb
//        self.fat = searchResult.fat
//        self.protein = searchResult.protein
//        _width = .constant(Self.DefaultWidth)
//    }
    
//    init(food: Food,
//        width: Binding<CGFloat> = .constant(Self.DefaultWidth)
//    ) {
//        self.carb = food.carb
//        self.fat = food.fat
//        self.protein = food.protein
//        _width = width
//    }

    init(food: Food2,
        width: Binding<CGFloat> = .constant(Self.DefaultWidth)
    ) {
        self.carb = food.carb
        self.fat = food.fat
        self.protein = food.protein
        _width = width
    }

    init(
        c: Double,
        f: Double,
        p: Double,
        width: Binding<CGFloat> = .constant(Self.DefaultWidth)
    ) {
        self.carb = c
        self.fat = f
        self.protein = p
        _width = width
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if totalEnergy == 0 {
                Color.clear
                    .background(Color(.quaternaryLabel).gradient)
            } else {
                Color.clear
                    .frame(width: carbWidth)
                    .background(Macro.carb.fillColor(for: colorScheme).gradient)
                Color.clear
                    .frame(width: fatWidth)
                    .background(Macro.fat.fillColor(for: colorScheme).gradient)
                Color.clear
                    .frame(width: proteinWidth)
                    .background(Macro.protein.fillColor(for: colorScheme).gradient)
            }
        }
        .frame(width: width, height: 10)
        .cornerRadius(2)
        /// No shadows 🙅🏽‍♂️ as this causes stuttering while scrolling (even on the most performant devices)
//        .shadow(radius: 1, x: 0, y: 1.5)
//        .shadow(color: Color(.systemFill), radius: 1, x: 0, y: 1.5)
    }
    
    var totalEnergy: CGFloat {
        (carb * KcalsPerGramOfCarb) + (protein * KcalsPerGramOfProtein) + (fat * KcalsPerGramOfFat)
    }
    var carbWidth: CGFloat {
        guard totalEnergy != 0 else { return 0 }
        return ((carb * KcalsPerGramOfCarb) / totalEnergy) * width
    }
    
    var proteinWidth: CGFloat {
        guard totalEnergy != 0 else { return 0 }
        return ((protein * KcalsPerGramOfProtein) / totalEnergy) * width
    }
    
    var fatWidth: CGFloat {
        guard totalEnergy != 0 else { return 0 }
        return ((fat * KcalsPerGramOfFat) / totalEnergy) * width
    }
}
