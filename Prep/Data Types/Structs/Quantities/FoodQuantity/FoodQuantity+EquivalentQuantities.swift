import Foundation

import FoodDataTypes

extension FoodQuantity {
    func equivalentQuantities(using volumeUnits: VolumeUnits = .defaultUnits) -> [FoodQuantity] {
        let units = food.possibleUnits(without: unit, using: volumeUnits)
        var quantites = units
            .compactMap { convert(to: $0) }
            .filter({ $0.value >= 0.1 && $0.value < 1000 })
        
        quantites.pickUnitBetween(smallerUnit: .weight(.g), largerUnit: .weight(.kg))
        quantites.pickUnitBetween(smallerUnit: .weight(.oz), largerUnit: .weight(.lb))
        quantites.pickUnitBetween(smallerUnit: .volume(.mL), largerUnit: .volume(.liter))
        
        return quantites
    }
}

extension Array where Element == FoodQuantity {
    /// if both units are present, picks the parent if its `> 1.0`, otherwise picks the child
    mutating func pickUnitBetween(smallerUnit: FoodQuantity.Unit, largerUnit: FoodQuantity.Unit) {
        guard let largerQuantity = first(where: { $0.unit == largerUnit }),
           let _ = first(where: { $0.unit == smallerUnit })
        else { return }
        
        if largerQuantity.value >= 1.0 {
            self.removeAll(where: { $0.unit == smallerUnit })
        } else {
            self.removeAll(where: { $0.unit == largerUnit })
        }
    }
}
