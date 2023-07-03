import SwiftUI

import Charts
import FoodDataTypes

struct FoodCell: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let emoji: String
    let name: String
    let detail: String?
    let brand: String?
    let carb: Double
    let fat: Double
    let protein: Double

    @Binding var showingForm: Bool
    
//    init(food: Food, showingForm: Binding<Bool>) {
//        self.emoji = food.emoji
//        self.name = food.name
//        self.detail = food.detail
//        self.brand = food.brand
//        self.carb = food.carb
//        self.fat = food.fat
//        self.protein = food.protein
//        _showingForm = showingForm
//    }

//    init(foodResult result: FoodResult) {
//        self.emoji = result.emoji
//        self.name = result.name
//        self.detail = result.detail
//        self.brand = result.brand
//        self.carb = result.carb
//        self.fat = result.fat
//        self.protein = result.protein
//        _showingForm = .constant(false)
//    }

    init(food: Food, showingForm: Binding<Bool> = .constant(false)) {
        self.emoji = food.emoji
        self.name = food.name
        self.detail = food.detail
        self.brand = food.brand
        self.carb = food.carb
        self.fat = food.fat
        self.protein = food.protein
        _showingForm = showingForm
    }

    var body: some View {
        HStack {
            emojiText
                .popover(isPresented: $showingForm) {
                    foodForm
                }
            nameTexts
            Spacer()
//            foodBadge
            pieChart
        }
    }
    
    var foodForm: some View {
        FoodForm()
    }
    
    var greyColor: Color { Color(hex: "6F7E88") }

    @ViewBuilder
    var pieChart: some View {
        if !(carb == 0 && protein == 0 && fat == 0) {
            macrosChart
        } else {
            emptyChart
        }
    }
    
    var emptyChart: some View {
        var chartData: [MacroValue] {
            [
                MacroValue(macro: .carb, value: 100)
            ]
        }

        return Chart(chartData, id: \.macro) { macroValue in
            SectorMark(
                angle: .value("kcal", macroValue.kcal),
                innerRadius: .ratio(0.5),
                angularInset: 0.5
            )
            .cornerRadius(3)
            .foregroundStyle(by: .value("Macro", macroValue.macro))
        }
        .chartForegroundStyleScale([Macro.carb : greyColor])
        .chartLegend(.hidden)
        .frame(width: 28, height: 28)
    }
    
    var macrosChart: some View {
        var chartData: [MacroValue] {
            [
                MacroValue(macro: .carb, value: carb),
                MacroValue(macro: .fat, value: fat),
                MacroValue(macro: .protein, value: protein)
            ]
        }

        return Chart(chartData, id: \.macro) { macroValue in
            SectorMark(
                angle: .value("kcal", macroValue.kcal),
                innerRadius: .ratio(0.5),
                angularInset: 0.5
            )
            .cornerRadius(3)
            .foregroundStyle(by: .value("Macro", macroValue.macro))
        }
        .chartForegroundStyleScale(Macro.chartStyleScale(colorScheme))
        .chartLegend(.hidden)
        .frame(width: 28, height: 28)
    }
    
    var foodBadge: some View {
        FoodBadge(c: carb, f: fat, p: protein)
    }
    
    var emojiText: some View {
        Text(emoji)
    }
    
    var nameTexts: some View {
        var view = Text(name)
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(Color(.label))
        if let detail = detail, !detail.isEmpty {
            view = view
            + Text(", ")
            
                .font(.callout)
                .fontWeight(.regular)
                .foregroundStyle(Color(.secondaryLabel))
            + Text(detail)
                .font(.callout)
                .fontWeight(.regular)
                .foregroundStyle(Color(.secondaryLabel))
        }
        if let brand = brand, !brand.isEmpty {
            view = view
//            + Text(detail?.isEmpty == true ? "" : ", ")
            + Text(", ")
                .font(.callout)
                .fontWeight(.regular)
                .foregroundStyle(Color(.tertiaryLabel))
            + Text(brand)
                .font(.callout)
                .fontWeight(.regular)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        view = view

        .font(.callout)
        .fontWeight(.semibold)
        .foregroundStyle(Color(.secondaryLabel))
        
        return view
            .alignmentGuide(.listRowSeparatorLeading) { dimensions in
                dimensions[.leading]
            }
    }
}
