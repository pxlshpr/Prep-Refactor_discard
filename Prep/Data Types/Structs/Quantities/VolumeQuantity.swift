import Foundation

struct VolumeQuantity: Hashable {
    let value: Double
    let unit: VolumeUnit
}

extension VolumeQuantity {
    init(_ value: Double, _ unit: VolumeUnit) {
        self.init(value: value, unit: unit)
    }
}

extension VolumeQuantity: Equatable {
    /// Note: Equality is determined by comparing values to **two decimal places**
    static func ==(lhs: VolumeQuantity, rhs: VolumeQuantity) -> Bool {
        lhs.unit == rhs.unit
        && lhs.value.rounded(toPlaces: 2) == rhs.value.rounded(toPlaces: 2)
    }
}

extension VolumeQuantity {
    var valueInML: Double {
        value * unit.mL
    }
    
    func convert(to volumeUnit: VolumeUnit) -> Double {
        valueInML / volumeUnit.mL
    }
}
