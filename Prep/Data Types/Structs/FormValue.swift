import Foundation

struct FormValue {
    let amount: Double
    let unit: FormUnit
    
    init(_ amount: Double, _ unit: FormUnit) {
        self.amount = amount
        self.unit = unit
    }
}

