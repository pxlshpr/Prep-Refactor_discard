import Foundation

extension FoodQuantity {

    struct Size: Hashable {
        let quantity: Double
        let volumeUnit: VolumeUnit?
        let name: String
        let value: Double
        let unit: Unit
    }
}

extension VolumeUnit {
    func scale(against other: VolumeUnit?) -> Double {
        guard let other else { return 1 }
        return mL / other.mL
    }
}

extension SizeQuantity {
    var sizeVolumeScale: Double {
        size.volumePrefixScale(for: volumeUnit)
    }
    
    func volumePrefixScale(for otherVolumeUnit: VolumeUnit?) -> Double {
        guard let volumeUnit, let otherVolumeUnit else {
            return 1
        }
//        return (volumePrefixUnit.mL / otherVolumePrefix.mL) * sizeVolumeScale
        return (volumeUnit.mL / otherVolumeUnit.mL)
    }
}

extension FoodQuantity.Size {
    
    func volumePrefixScale(for otherVolumePrefix: VolumeUnit?) -> Double {
        guard let volumeUnit, let otherVolumePrefix else {
            return 1
        }
        return volumeUnit.mL / otherVolumePrefix.mL
    }
    
    func namePrefixed(with volumeUnit: VolumeUnit?) -> String {
        if let volumeUnit {
            return "\(volumeUnit.abbreviation) \(name)"
        } else {
            return prefixedName
        }
    }
    
    var prefixedName: String {
        if let volumePrefixString {
            return "\(volumePrefixString) \(name)"
        } else {
            return name
        }
    }
    
    var volumePrefixString: String? {
        volumeUnit?.abbreviation
    }

    var unitValue: Double {
        guard quantity > 0 else { return 0 }
        return value / quantity
    }
}

extension VolumeUnit {
    var mL: Double {
        switch self {
        case .mL:                               return 1
        case .liter:                            return 1000
            
        case .cupUSLegal:                       return 240
        case .cupUSCustomary:                   return 236.59
        case .cupImperial:                      return 284.13
        case .cupMetric:                        return 250
        case .cupCanada:                        return 227.30
        case .cupLatinAmerica:                  return 200
        case .cupJapanTraditional:              return 180.39
        case .cupJapanModern:                   return 200
        case .cupRussianProper:                 return 100
        case .cupRussianGlassRegular:           return 200
        case .cupRussianGlassLarge:             return 250
            
        case .teaspoonMetric:                   return 5
        case .teaspoonUS:                       return 4.93
            
        case .tablespoonMetric:                 return 15
        case .tablespoonUS:                     return 14.79
        case .tablespoonAustralia:              return 20
            
        case .fluidOunceUSNutritionLabeling:    return 30
        case .fluidOunceUSCustomary:            return 29.57
        case .fluidOunceImperial:               return 28.41
            
        case .pintUSLiquid:                     return 473.18
        case .pintUSDry:                        return 550.61
        case .pintImperial:                     return 568.26
        case .pintMetric:                       return 500
        case .pintFlemishPintje:                return 250
        case .pintIndia:                        return 330
        case .pintSouthAustralia:               return 425
        case .pintAustralia:                    return 570
        case .pintRoyal:                        return 952
        case .pintCanada:                       return 1136.52
            
        case .quartUSLiquid:                    return 946.35
        case .quartUSDry:                       return 1101.22
        case .quartImperial:                    return 1136.52
        
        case .gallonUSLiquid:                   return 3785.41
        case .gallonUSDry:                      return 4404.88
        case .gallonImperial:                   return 4546.09

        }
    }
}

extension FoodQuantity.Size {
    init?(foodSize: FoodSize, in food: Food) {
        guard let unit = FoodQuantity.Unit(foodValue: foodSize.value, in: food) else {
            return nil
        }
                
        self.init(
            quantity: foodSize.quantity,
            volumeUnit: foodSize.volumeUnit,
            name: foodSize.name,
            value: foodSize.value.value,
            unit: unit
        )
    }
    
    init?(formSize: FormSize, in food: Food, volumeUnits: VolumeUnits) {
        guard let size = food.quantitySize(for: formSize.id) else {
            return nil
        }
        self = size
//        guard let quantity = formSize.quantity,
//              let amount = formSize.amount,
//              let unit = FoodQuantity.Unit(
//                formUnit: formSize.unit,
//                food: food,
//                volumeUnits: volumeUnits
//              )
//        else { return nil }
//
//        let volumePrefixUnit: VolumeUnit?
//        if let volumePrefixFormUnit = formSize.volumePrefixUnit {
//            guard let volumeUnit = volumeUnits.volumeUnit(for: volumePrefixFormUnit) else {
//                return nil
//            }
//            volumePrefixUnit = volumeUnit
//        } else {
//            volumePrefixUnit = nil
//        }
//
//        self.init(
//            quantity: quantity,
//            volumeUnit: volumePrefixUnit,
//            name: formSize.name,
//            value: amount,
//            unit: unit
//        )
    }
}
