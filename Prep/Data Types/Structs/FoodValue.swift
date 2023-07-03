import Foundation

struct FoodValue: Codable, Hashable {
    
    var value: Double
    var unitType: UnitType
    var weightUnit: WeightUnit?
    var volumeUnit: VolumeUnit?
    var sizeID: String?
    var sizeVolumeUnit: VolumeUnit?
    
    init(
        value: Double,
        unitType: UnitType,
        weightUnit: WeightUnit? = nil,
        volumeUnit: VolumeUnit? = nil,
        sizeID: String? = nil,
        sizeVolumeUnit: VolumeUnit? = nil
    ) {
        self.value = value
        self.unitType = unitType
        self.weightUnit = weightUnit
        self.volumeUnit = volumeUnit
        self.sizeID = sizeID
        self.sizeVolumeUnit = sizeVolumeUnit
    }
    
    /// Separators used for the string representation
    static let Separator = "_"
}

extension FoodValue {
    init(_ value: Double, _ unit: FormUnit) {
        self.init(
            value: value,
            unitType: unit.unitType,
            weightUnit: unit.weightUnit,
            volumeUnit: unit.volumeUnit,
            sizeID: unit.sizeID,
            sizeVolumeUnit: unit.sizeVolumeUnit
        )
    }
}

extension FoodValue {
    func formUnit(for food: Food2) -> FormUnit? {
        switch unitType {
        case .serving:
            return .serving
        case .size:
            guard let sizeID,
                  let foodSize = food.sizes.first(where: { $0.id == sizeID }),
                  let formSize = foodSize.formSize(for: food)
            else { return nil }
            return .size(formSize, sizeVolumeUnit)
        case .volume:
            guard let volumeUnit else { return nil }
            return .volume(volumeUnit)
        case .weight:
            guard let weightUnit else { return nil }
            return .weight(weightUnit)
        }
    }
}

extension FoodValue {
    
    var asString: String {
        "\(value)"
        + "\(Self.Separator)\(unitType.rawValue)"
        + "\(Self.Separator)\(weightUnit?.rawValue ?? NilInt)"
        + "\(Self.Separator)\(volumeUnit?.rawValue ?? NilInt)"
        + "\(Self.Separator)\(sizeID ?? "")"
        + "\(Self.Separator)\(sizeVolumeUnit?.rawValue ?? NilInt)"
    }
    
    init(string: String) {
        let components = string.components(separatedBy: Self.Separator)
        guard components.count == 6 else { fatalError() }
        let valueString = components[0]
        let unitTypeString = components[1]
        let weightUnitString = components[2]
        let volumeUnitString = components[3]
        let sizeIdString = components[4]
        let sizeVolumeUnitString = components[5]
        
        guard let value = Double(valueString) else { fatalError() }

        guard let unitTypeInt = Int(unitTypeString) else { fatalError() }
        guard let unitType = UnitType(rawValue: unitTypeInt) else { fatalError() }

        guard let weightUnitInt = Int(weightUnitString) else { fatalError() }
        let weightUnit: WeightUnit?
        if weightUnitInt == NilInt {
            weightUnit = nil
        } else {
            weightUnit = WeightUnit(rawValue: weightUnitInt)
        }

        guard let volumeUnitInt = Int(volumeUnitString) else { fatalError() }
        let volumeUnit: VolumeUnit?
        if volumeUnitInt == NilInt {
            volumeUnit = nil
        } else {
            volumeUnit = VolumeUnit(rawValue: volumeUnitInt)
        }

        let sizeID: String?
        if sizeIdString.isEmpty {
            sizeID = nil
        } else {
            sizeID = sizeIdString
        }

        guard let sizeVolumeUnitInt = Int(sizeVolumeUnitString) else { fatalError() }
        let sizeVolumeUnit: VolumeUnit?
        if sizeVolumeUnitInt == NilInt {
            sizeVolumeUnit = nil
        } else {
            sizeVolumeUnit = VolumeUnit(rawValue: sizeVolumeUnitInt)
        }

        self.value = value
        self.unitType = unitType
        self.weightUnit = weightUnit
        self.volumeUnit = volumeUnit
        self.sizeID = sizeID
        self.sizeVolumeUnit = sizeVolumeUnit
    }
}

struct LegacyFoodValue: Codable, Hashable {
    var value: Double
    var unitType: UnitType
    var weightUnit: WeightUnit?
    var volumeExplicitUnit: VolumeUnit?
    var sizeUnitId: String?
    var sizeUnitVolumePrefixExplicitUnit: VolumeUnit?
    
    init(
        value: Double,
        unitType: UnitType,
        weightUnit: WeightUnit? = nil,
        volumeExplicitUnit: VolumeUnit? = nil,
        sizeUnitId: String? = nil,
        sizeUnitVolumePrefixExplicitUnit: VolumeUnit? = nil
    ) {
        self.value = value
        self.unitType = unitType
        self.weightUnit = weightUnit
        self.volumeExplicitUnit = volumeExplicitUnit
        self.sizeUnitId = sizeUnitId
        self.sizeUnitVolumePrefixExplicitUnit = sizeUnitVolumePrefixExplicitUnit
    }
    
    var foodValue: FoodValue {
        FoodValue(
            value: value,
            unitType: unitType,
            weightUnit: weightUnit,
            volumeUnit: volumeExplicitUnit,
            sizeID: sizeUnitId,
            sizeVolumeUnit: sizeUnitVolumePrefixExplicitUnit
        )
    }
}

extension FoodValue {
    
    init(legacy: LegacyFoodValue) {
        self.init(
            value: legacy.value,
            unitType: legacy.unitType,
            weightUnit: legacy.weightUnit,
            volumeUnit: legacy.volumeExplicitUnit,
            sizeID: legacy.sizeUnitId,
            sizeVolumeUnit: legacy.sizeUnitVolumePrefixExplicitUnit
        )
    }
    
    var legacy: LegacyFoodValue {
        LegacyFoodValue(
            value: value,
            unitType: unitType,
            weightUnit: weightUnit,
            volumeExplicitUnit: volumeUnit,
            sizeUnitId: sizeID,
            sizeUnitVolumePrefixExplicitUnit: sizeVolumeUnit
        )
    }
}

//MARK: - Raw Value

extension FoodValue {
    var rawValue: FoodValueRaw {
        FoodValueRaw(foodValue: self)
    }
}

struct FoodValueRaw: Codable, Hashable {
    var value: Double
    var unitTypeValue: Int
    
    /// Optionals
    var weightUnitValue: Int
    var volumeUnitValue: Int
    var sizeIDValue: String
    var sizeVolumeUnitValue: Int
    
    static var NilValue: FoodValueRaw {
        FoodValueRaw(
            value: NilDouble,
            unitTypeValue: NilInt,
            weightUnitValue: NilInt,
            volumeUnitValue: NilInt,
            sizeIDValue: NilString,
            sizeVolumeUnitValue: NilInt
        )
    }
    
    init(foodValue: FoodValue) {
        self.init(
            value: foodValue.value,
            unitTypeValue: foodValue.unitType.rawValue,
            weightUnitValue: foodValue.weightUnit?.rawValue ?? NilInt,
            volumeUnitValue: foodValue.volumeUnit?.rawValue ?? NilInt,
            sizeIDValue: foodValue.sizeID ?? NilString,
            sizeVolumeUnitValue: foodValue.sizeVolumeUnit?.rawValue ?? NilInt
        )
    }
    
    var foodValue: FoodValue {
        FoodValue(
            value: value,
            unitType: unitType,
            weightUnit: weightUnit,
            volumeUnit: volumeUnit,
            sizeID: sizeIDValue == NilString ? nil : sizeIDValue,
            sizeVolumeUnit: sizeVolumeUnit
        )
    }
    
    init(
        value: Double,
        unitTypeValue: Int,
        weightUnitValue: Int,
        volumeUnitValue: Int,
        sizeIDValue: String,
        sizeVolumeUnitValue: Int
    ) {
        self.value = value
        self.unitTypeValue = unitTypeValue
        self.weightUnitValue = weightUnitValue
        self.volumeUnitValue = volumeUnitValue
        self.sizeIDValue = sizeIDValue
        self.sizeVolumeUnitValue = sizeVolumeUnitValue
    }
    
    var unitType: UnitType {
        get {
            UnitType(rawValue: unitTypeValue) ?? .serving
        }
        set {
            unitTypeValue = newValue.rawValue
        }
    }
    
    var weightUnit: WeightUnit? {
        get {
            guard weightUnitValue != NilInt else { return nil }
            return WeightUnit(rawValue: weightUnitValue)
        }
        set {
            if let newValue {
                weightUnitValue = newValue.rawValue
            } else {
                weightUnitValue = NilInt
            }
        }
    }
    
    var volumeUnit: VolumeUnit? {
        get {
            guard volumeUnitValue != NilInt else { return nil }
            return VolumeUnit(rawValue: volumeUnitValue)
        }
        set {
            if let newValue {
                volumeUnitValue = newValue.rawValue
            } else {
                volumeUnitValue = NilInt
            }
        }
    }
    
    var sizeVolumeUnit: VolumeUnit? {
        get {
            guard sizeVolumeUnitValue != NilInt else { return nil }
            return VolumeUnit(rawValue: sizeVolumeUnitValue)
        }
        set {
            if let newValue {
                sizeVolumeUnitValue = newValue.rawValue
            } else {
                sizeVolumeUnitValue = NilInt
            }
        }
    }
    
    var sizeID: String? {
        get {
            sizeIDValue == NilString ? nil : sizeIDValue
        }
        set {
            sizeIDValue = newValue ?? NilString
        }
    }
}

extension FoodValue {
    func foodSizeUnit(in food: Food) -> FoodSize? {
        food.sizes.first(where: { $0.id == self.sizeID })
    }
    
    func formSizeUnit(in food: Food) -> FormSize? {
        guard let foodSize = foodSizeUnit(in: food) else {
            return nil
        }
        return FormSize(foodSize: foodSize, in: food.sizes)
    }

    func isWeightBased(in food: Food) -> Bool {
        unitType == .weight || hasWeightBasedSizeUnit(in: food)
    }

    func isVolumeBased(in food: Food) -> Bool {
        unitType == .volume || hasVolumeBasedSizeUnit(in: food)
    }
    
    func hasVolumeBasedSizeUnit(in food: Food) -> Bool {
        formSizeUnit(in: food)?.isVolumeBased == true
    }
    
    func hasWeightBasedSizeUnit(in food: Food) -> Bool {
        formSizeUnit(in: food)?.isWeightBased == true
    }
}
