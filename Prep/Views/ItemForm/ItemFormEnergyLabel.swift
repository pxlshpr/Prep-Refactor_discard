import SwiftUI
import Charts

import FoodDataTypes

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
