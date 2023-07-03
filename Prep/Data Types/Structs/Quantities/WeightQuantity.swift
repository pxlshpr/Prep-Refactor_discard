import Foundation

struct WeightQuantity: Hashable {
    let value: Double
    let unit: WeightUnit
}

extension WeightQuantity {
    init(_ value: Double, _ unit: WeightUnit) {
        self.init(value: value, unit: unit)
    }
}

/// Note: Equality is determined by comparing values to **two decimal places**
extension WeightQuantity: Equatable {
    static func ==(lhs: WeightQuantity, rhs: WeightQuantity) -> Bool {
        lhs.unit == rhs.unit
        && lhs.value.rounded(toPlaces: 2) == rhs.value.rounded(toPlaces: 2)
    }
}

extension WeightQuantity {
    var valueInGrams: Double {
        value * unit.g
    }
    
    func convert(to weightUnit: WeightUnit) -> Double {
        valueInGrams / weightUnit.g
    }
}
