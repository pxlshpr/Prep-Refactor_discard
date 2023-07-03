import SwiftUI
import Charts

import FoodDataTypes

struct ItemFormFoodLabel: View {

    let food: Food?
    
    var body: some View {
        if let food {
            HStack {
                HStack(alignment: .top) {
                    Text("Food")
                        .foregroundStyle(Color(.label))
                    Spacer()
                    Text(food.foodName)
//                        .foregroundStyle(Color(.secondaryLabel))
                        .foregroundStyle(Color(.label))
                }
                .multilineTextAlignment(.trailing)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(.tertiaryLabel))
                    .imageScale(.small)
                    .fontWeight(.semibold)
            }
        }
    }
}

struct ItemFormEnergyLabel: View {
    
    @Environment(\.colorScheme) var colorScheme
    let string: String
    let food: Food?

    var body: some View {
        HStack {
            Text("Energy")
                .foregroundStyle(Color(.label))
            Spacer()
            Text(string)
                .font(.headline)
                .foregroundStyle(Color(.label))
            pieChart
        }
    }
    
    @ViewBuilder
    var pieChart: some View {
        if let food {
            Chart(food.macrosChartData, id: \.macro) { macroValue in
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
    }

}