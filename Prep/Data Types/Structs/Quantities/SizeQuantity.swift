import Foundation

struct SizeQuantity: Hashable {
    let value: Double
    let size: FoodQuantity.Size
    var volumeUnit: VolumeUnit? = nil
}

extension SizeQuantity {
    /// The scale to be applied, to convert values from the `size.volumePrefixUnit` to the specified `volumePrefixUnit`
    var volumePrefixScale: Double {
        size.volumePrefixScale(for: volumeUnit)
    }
}

extension SizeQuantity {
    init(_ value: Double, _ size: FoodQuantity.Size, _ volumeUnit: VolumeUnit?) {
        self.init(value: value, size: size, volumeUnit: volumeUnit)
    }
    
    init(_ value: Double, _ size: FoodQuantity.Size) {
        self.init(value: value, size: size)
    }
}

extension SizeQuantity: Equatable {
    /// Note: Equality is determined by comparing values to **two decimal places**
    static func ==(lhs: SizeQuantity, rhs: SizeQuantity) -> Bool {
        lhs.size == rhs.size
        && lhs.volumeUnit == rhs.volumeUnit
        && lhs.value.rounded(toPlaces: 2) == rhs.value.rounded(toPlaces: 2)
    }
}
