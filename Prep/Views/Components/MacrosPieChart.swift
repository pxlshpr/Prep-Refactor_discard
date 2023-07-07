import SwiftUI
import Charts

import FoodDataTypes

struct MacrosPieChart: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var data: [MacroValue]
    
    var body: some View {
        let _ = Self._printChanges()
        return Chart(data, id: \.macro) { macroValue in
            SectorMark(
                angle: .value("kcal", macroValue.kcal),
                angularInset: 1.5
            )
            .cornerRadius(5)
            .foregroundStyle(by: .value("Macro", macroValue.macro))
        }
        .chartForegroundStyleScale(Macro.chartStyleScale(colorScheme))
        .chartLegend(position: .trailing, alignment: .center)
        .padding(.vertical, 5)
    }
}
