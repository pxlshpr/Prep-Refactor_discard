import Foundation

struct FoodDensity: Codable, Hashable {
    var weightAmount: Double
    var weightUnit: WeightUnit
    var volumeAmount: Double
    var volumeUnit: VolumeUnit
    
    init(
        weightAmount: Double = 0,
        weightUnit: WeightUnit = .g,
        volumeAmount: Double = 0,
        volumeUnit: VolumeUnit = .cupMetric
    ) {
        self.weightAmount = weightAmount
        self.weightUnit = weightUnit
        self.volumeAmount = volumeAmount
        self.volumeUnit = volumeUnit
    }
}

struct LegacyFoodDensity: Codable, Hashable {
    var weightAmount: Double
    var weightUnit: WeightUnit
    var volumeAmount: Double
    var volumeExplicitUnit: VolumeUnit
}

extension LegacyFoodDensity {
    var density: FoodDensity {
        FoodDensity(
            weightAmount: weightAmount,
            weightUnit: weightUnit,
            volumeAmount: volumeAmount,
            volumeUnit: volumeExplicitUnit
        )
    }
}

//MARK: - Raw Value

extension FoodDensity {
    var rawValue: FoodDensityRaw {
        FoodDensityRaw(foodDensity: self)
    }
}

struct FoodDensityRaw: Codable, Hashable {
    var weightAmount: Double
    var weightUnitValue: Int
    var volumeAmount: Double
    var volumeUnitValue: Int
    
    static var NilValue: FoodDensityRaw {
        FoodDensityRaw(
            weightAmount: NilDouble,
            weightUnitValue: NilInt,
            volumeAmount: NilDouble,
            volumeUnitValue: NilInt
        )
    }
    
    init(foodDensity: FoodDensity) {
        self.init(
            weightAmount: foodDensity.weightAmount,
            weightUnitValue: foodDensity.weightUnit.rawValue,
            volumeAmount: foodDensity.volumeAmount,
            volumeUnitValue: foodDensity.volumeUnit.rawValue
        )
    }
    
    var legacyFoodDensity: LegacyFoodDensity {
        LegacyFoodDensity(
            weightAmount: weightAmount,
            weightUnit: weightUnit,
            volumeAmount: volumeAmount,
            volumeExplicitUnit: volumeUnit
        )
    }

    var foodDensity: FoodDensity {
        FoodDensity(
            weightAmount: weightAmount,
            weightUnit: weightUnit,
            volumeAmount: volumeAmount,
            volumeUnit: volumeUnit
        )
    }

    init(
        weightAmount: Double,
        weightUnitValue: Int,
        volumeAmount: Double,
        volumeUnitValue: Int
    ) {
        self.weightAmount = weightAmount
        self.weightUnitValue = weightUnitValue
        self.volumeAmount = volumeAmount
        self.volumeUnitValue = volumeUnitValue
    }
    
    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitValue) ?? .g }
        set { self.weightUnitValue = newValue.rawValue}
    }

    var volumeUnit: VolumeUnit {
        get { VolumeUnit(rawValue: volumeUnitValue) ?? .mL }
        set { self.volumeUnitValue = newValue.rawValue }
    }
}

extension FoodDensity {
    func convert(weight: WeightQuantity) -> VolumeQuantity {
        /// Protect against divison by 0
        guard self.weightAmount > 0 else { return VolumeQuantity(value: 0, unit: volumeUnit) }
        
        /// first convert the weight to the unit we have in the density
        let convertedWeight = weight.convert(to: self.weightUnit)
        
        let volumeAmount = (convertedWeight * self.volumeAmount) / self.weightAmount
        return VolumeQuantity(value: volumeAmount, unit: self.volumeUnit)
    }
    
    func convert(volume: VolumeQuantity) -> WeightQuantity {
        /// Protect against divison by 0
        guard self.volumeAmount > 0 else { return WeightQuantity(value: 0, unit: weightUnit) }
        
        /// first convert the volume to the unit we have in the density
        let convertedVolume = volume.convert(to: self.volumeUnit)
        
        let weightAmount = (convertedVolume * self.weightAmount) / self.volumeAmount
        return WeightQuantity(value: weightAmount, unit: weightUnit)
    }
}
