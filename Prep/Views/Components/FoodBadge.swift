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

    init(food: Food,
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

//let DefaultBadgeWidth: CGFloat = 30.0
//
//func calculateRelativeEnergy(
//    for value: Double,
//    within values: [Double],
//    maxWidth: CGFloat? = nil
//) -> CGFloat {
//    let sorted = values
//        .filter { $0 > 0 }
//        .sorted { $0 > $1 }
//    guard let largest = sorted.first,
//          let smallest = sorted.last
//    else { return DefaultBadgeWidth }
//    
//    return calculateRelativeEnergy(
//        for: value,
//        largest: largest,
//        smallest: smallest,
//        maxWidth: maxWidth
//    )
//}
//
//func calculateRelativeEnergy(
//    for value: Double,
//    largest: Double,
//    smallest: Double,
//    maxWidth: CGFloat? = nil
//) -> CGFloat {
//    
//    let maxWidth = maxWidth ?? (0.34883721 * 428) /// Using hardcoded width of iPhone 13 Pro Max
//
//    let min = DefaultBadgeWidth
//    let max: CGFloat = maxWidth
//    
//    guard largest > 0, smallest > 0, value <= largest, value >= smallest else {
//        return DefaultBadgeWidth
//    }
//    
//    /// First try and scale values such that smallest value gets the DefaultWidth and everything else scales accordingly
//    /// But first see if this results in the largest value crossing the MaxWidth, and if so
//    guard (largest/smallest) * min <= max else {
//        /// scale values such that largest value gets the MaxWidth and everything else scales accordingly
//        let percent = value/largest
//        let width = percent * max
//        return width
//    }
//    
//    let percent = value/smallest
//    let width = percent * min
//    return width
//}
