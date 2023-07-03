import Foundation

extension FoodQuantity {
    
    indirect enum Unit: Hashable {
        case weight(WeightUnit)
        case volume(VolumeUnit)
        case size(Size, VolumeUnit?)
        case serving
    }
}

extension FoodQuantity.Unit {
    var formUnit: FormUnit {
        FormUnit(foodQuantityUnit: self)
    }

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

    var sizeVolumePrefixExplicitUnit: VolumeUnit? {
        switch self {
        case .size(_, let volumeUnit):
            return volumeUnit
        default:
            return nil
        }
    }
}

extension FoodQuantity.Unit: CustomStringConvertible {
    var description: String {
        switch self {
        case .weight(let weightUnit):
            return weightUnit.name
        case .volume(let volumeUnit):
            return volumeUnit.name
        case .size(let size, let volumeUnit):
            return size.namePrefixed(with: volumeUnit)
        case .serving:
            return "serving"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .weight(let weightUnit):
            return weightUnit.abbreviation
        case .volume(let volumeUnit):
            return volumeUnit.abbreviation
        case .size(let size, let volumeUnit):
            return size.namePrefixed(with: volumeUnit)
        case .serving:
            return "serving"
        }
    }
}


//MARK: FoodValue → FoodQuantity.Unit
extension FoodQuantity.Unit {
    init?(foodValue: FoodValue, in food: Food) {
        switch foodValue.unitType {
            
        case .serving:
            self = .serving
            
        case .weight:
            guard let weightUnit = foodValue.weightUnit else { return nil }
            self = .weight(weightUnit)
            
        case .volume:
            guard let volumeUnit = foodValue.volumeUnit else { return nil }
            self = .volume(volumeUnit)
            
        case .size:
            guard let foodSize = food.sizes.sizeMatchingUnitSizeInFoodValue(foodValue),
                  let size = FoodQuantity.Size(foodSize: foodSize, in: food)
            else { return nil }
            self = .size(size, foodValue.sizeVolumeUnit)
        }
    }
}

//MARK: FormUnit → FoodQuantity.Unit
extension FoodQuantity.Unit {
    init?(formUnit: FormUnit, food: Food, volumeUnits: VolumeUnits) {
        switch formUnit {
            
        case .weight(let weightUnit):
            self = .weight(weightUnit)
            
        case .volume(let volumeUnit):
            self = .volume(volumeUnits.volumeUnit(for: volumeUnit.type))
            
        case .size(let formSize, let volumeUnit):
            guard let size = FoodQuantity.Size(
                formSize: formSize,
                in: food,
                volumeUnits: volumeUnits
            ) else { return nil }
            
            if let volumeUnit {
                self = .size(size, volumeUnits.volumeUnit(for: volumeUnit.type))
            } else {
                self = .size(size, nil)
            }
            
        case .serving:
            self = .serving
        }
    }
}
