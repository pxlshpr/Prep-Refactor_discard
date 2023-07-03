import Foundation

/**
 A unit used to describe the value of a food in the context of a Form.
 */
indirect enum FormUnit: Hashable, Codable {
    case weight(WeightUnit)
    case volume(VolumeUnit)
    /// A`FormSize` this unit represents, along with an optional `VolumeUnit`
    /// used as a prefix for volume-based sizes (e.g. tbps used for a `FormSize` that's
    /// defined as 'cups, shredded')
    case size(FormSize, VolumeUnit?)
    case serving
}

extension FormUnit {
    var volumeUnit: VolumeUnit? {
        switch self {
        case .volume(let volumeUnit):   volumeUnit
        default:                        nil
        }
    }

    var weightUnit: WeightUnit? {
        switch self {
        case .weight(let weightUnit):   weightUnit
        default:                        nil
        }
    }

    var isVolumeBased: Bool {
        switch self {
        case .size(let size, _):    size.isVolumeBased
        case .volume:               true
        default:                    false
        }
    }
    
    var isServingBased: Bool {
        switch self {
        case .size(let size, _):    size.isServingBased
        case .serving:              true
        default:                    false
        }
    }
    
    var isSizeBased: Bool {
        switch self {
        case .size: true
        default:    false
        }
    }

    var isWeightBased: Bool {
        switch self {
        case .size(let size, _):    size.isWeightBased
        case .weight:               true
        default:                    false
        }
    }
    
    var sizeID: String? {
        switch self {
        case .size(let size, _):    size.id
        default:                    nil
        }
    }

    var replacementUnit: FormUnit {
        switch self {
        case .size(let size, _):
            return size.replacementUnit
        default:
            return self
        }
    }

    var sizeVolumeUnit: VolumeUnit? {
        switch self {
        case .size(_, let volumeUnit):  volumeUnit
        default:                        nil
        }
    }

    var isWeight: Bool {
        switch self {
        case .weight:   true
        default:        false
        }
    }
    
    var name: String {
        switch self {
        case .weight(let weightUnit):
            return weightUnit.name
        case .volume(let volumeUnit):
            return volumeUnit.name
        case .size(let size, let volumeUnit):
            return size.fullName(volumeUnit: volumeUnit)
        case .serving:
            return "serving"
        }
    }
    
    var abbreviation: String {
        switch self {
        case .weight(let weightUnit):
            return weightUnit.abbreviation
        case .volume(let volumeUnit):
            return volumeUnit.abbreviation
        case .size(let size, let volumeUnit):
            return size.fullName(volumeUnit: volumeUnit)
        case .serving:
            return "serving"
        }
    }
}

extension FormUnit {
    var unitType: UnitType {
        switch self {
        case .weight:
            return .weight
        case .volume:
            return .volume
        case .size:
            return .size
        case .serving:
            return .serving
        }
    }
}

//MARK: - FoodLabelUnit + FormUnit

import FoodDataTypes

extension FoodLabelUnit {
    var formUnit: FormUnit? {
        switch self {
        case .cup:  .volume(.cupMetric)
        case .mg:   .weight(.mg)
        case .g:    .weight(.g)
        case .oz:   .weight(.oz)
        case .ml:   .volume(.mL)
        case .tbsp: .volume(.tablespoonMetric)
        default:    nil
        }
    }
}

import Foundation

extension FormUnit {

    init?(foodValue: FoodValue, in food: Food) {
        self.init(foodValue: foodValue, in: food.sizes)
    }

    //TODO: Quarantined *** TO BE REMOVED ***
    /// We can't use this as converting it to a `FormUnit` loses the explicit volume units
    init?(foodValue: FoodValue, in sizes: [FoodSize]) {
        switch foodValue.unitType {
        case .serving:
            self = .serving
        case .weight:
            guard let weightUnit = foodValue.weightUnit else {
                return nil
            }
            self = .weight(weightUnit)
        case .volume:
            guard let volumeUnit = foodValue.volumeUnit else {
                return nil
            }
            self = .volume(volumeUnit)
        case .size:
            guard let foodSize = sizes.sizeMatchingUnitSizeInFoodValue(foodValue),
                  let formSize = FormSize(foodSize: foodSize, in: sizes)
            else {
                return nil
            }
            self = .size(formSize, foodValue.sizeVolumeUnit)
        }
    }
    
    init?(volumeUnit: VolumeUnit) {
        self = .volume(volumeUnit)
    }
}


import Foundation

extension FormSize {
    init?(foodSize: FoodSize, in sizes: [FoodSize]) {
        let volumeUnit: VolumeUnit?
        if let sizeVolumeUnit = foodSize.volumeUnit {
            volumeUnit = sizeVolumeUnit
        } else {
            volumeUnit = nil
        }
        
        guard let unit = FormUnit(foodValue: foodSize.value, in: sizes) else {
            return nil
        }
        
        self.init(
            quantity: foodSize.quantity,
            volumeUnit: volumeUnit,
            name: foodSize.name,
            amount: foodSize.value.value,
            unit: unit
        )
    }
}

extension FormUnit {
    init(foodQuantityUnit: FoodQuantity.Unit) {
        switch foodQuantityUnit {
        case .weight(let weightUnit):
            self = .weight(weightUnit)
        case .volume(let volumeUnit):
            self = .volume(volumeUnit)
        case .size(let size, let volumeUnit):
            self = .size(FormSize(foodQuantitySize: size), volumeUnit)
        case .serving:
            self = .serving
        }
    }
}
