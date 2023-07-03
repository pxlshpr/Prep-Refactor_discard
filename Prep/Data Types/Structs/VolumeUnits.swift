import Foundation

import FoodDataTypes

struct VolumeUnits: Codable, Hashable {
    var cup: VolumeUnit
    var teaspoon: VolumeUnit
    var tablespoon: VolumeUnit
    var fluidOunce: VolumeUnit
    var pint: VolumeUnit
    var quart: VolumeUnit
    var gallon: VolumeUnit
    
    init(
        cup: VolumeUnit = .cupMetric,
        teaspoon: VolumeUnit = .teaspoonMetric,
        tablespoon: VolumeUnit = .tablespoonMetric,
        fluidOunce: VolumeUnit = .fluidOunceUSNutritionLabeling,
        pint: VolumeUnit = .pintMetric,
        quart: VolumeUnit = .quartUSLiquid,
        gallon: VolumeUnit = .gallonUSLiquid
    ) {
        //TODO: Validate the values, making sure we're assigning a 'cup' unit to cup etc...
        self.cup = cup
        self.teaspoon = teaspoon
        self.tablespoon = tablespoon
        self.fluidOunce = fluidOunce
        self.pint = pint
        self.quart = quart
        self.gallon = gallon
    }
}


extension VolumeUnits {
    mutating func set(_ volumeUnit: VolumeUnit) {
        switch volumeUnit.type {
        case .gallon:
            gallon = volumeUnit
        case .quart:
            quart = volumeUnit
        case .pint:
            pint = volumeUnit
        case .cup:
            cup = volumeUnit
        case .fluidOunce:
            fluidOunce = volumeUnit
        case .tablespoon:
            tablespoon = volumeUnit
        case .teaspoon:
            teaspoon = volumeUnit
        default:
            return
        }
    }
}

extension VolumeUnits {
    func contains(_ volumeUnit: VolumeUnit) -> Bool {
        false
    }
}

extension VolumeUnits {
    static var defaultUnits: VolumeUnits {
        VolumeUnits(
            cup: .cupMetric,
            teaspoon: .teaspoonMetric,
            tablespoon: .tablespoonMetric,
            fluidOunce: .fluidOunceUSNutritionLabeling,
            pint: .pintMetric,
            quart: .quartUSLiquid,
            gallon: .gallonUSLiquid
        )
    }
}

extension VolumeUnits {
    func volumeUnit(for type: VolumeUnitType) -> VolumeUnit {
        switch type {
        case .gallon:       return gallon
        case .quart:        return quart
        case .pint:         return pint
        case .cup:          return cup
        case .fluidOunce:   return fluidOunce
        case .tablespoon:   return tablespoon
        case .teaspoon:     return teaspoon
        case .mL:           return .mL
        case .liter:        return .liter
        }
    }
    
    func volumeUnit(for volumeFormUnit: FormUnit) -> VolumeUnit? {
        guard let unit = volumeFormUnit.volumeUnit else { return nil }
        return volumeUnit(for: unit.type)
    }
}
