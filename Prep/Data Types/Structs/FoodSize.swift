import Foundation

struct FoodSize: Identifiable, Codable, Hashable {
    
    var quantity: Double
    var name: String
    var volumeUnit: VolumeUnit?
    var value: FoodValue
    
    var id: String {
        if let volumeUnit {
            return "\(name)\(volumeUnit.type.rawValue)"
        } else {
            return name
        }
    }
    
    /// Separators used for the string representation
    static let Separator = "¬"
    static let ArraySeparator = "¦"
    
    init(
        quantity: Double,
        name: String,
        volumeUnit: VolumeUnit?,
        value: FoodValue
    ) {
        self.quantity = quantity
        self.name = name
        self.volumeUnit = volumeUnit
        self.value = value
    }
}

extension FoodSize {
    
    init(_ formSize: FormSize) {
        self.init(
            quantity: formSize.quantity ?? 1,
            name: formSize.name,
            volumeUnit: formSize.volumeUnit,
            value: formSize.foodValue
        )
    }
    
    func formSize(for food: Food2) -> FormSize? {
        guard let unit = self.value.formUnit(for: food) else {
            return nil
        }
        return FormSize(
            quantity: self.quantity,
            volumeUnit: self.volumeUnit,
            name: self.name,
            amount: self.value.value,
            unit: unit
        )
    }
}

extension FoodSize {
    var asString: String {
        "\(name)"
        + "\(Self.Separator)\(quantity)"
        + "\(Self.Separator)\(volumeUnit?.rawValue ?? NilInt)"
        + "\(Self.Separator)\(value.asString)"
    }
    
    init(string: String) {
        let components = string.components(separatedBy: Self.Separator)
        guard components.count == 4 else { fatalError() }
        let name = components[0]
        let quantityString = components[1]
        let volumeUnitString = components[2]
        let valueString = components[3]
        
        guard let quantity = Double(quantityString) else { fatalError() }

        guard let volumeUnitInt = Int(volumeUnitString) else { fatalError() }
        let volumeUnit: VolumeUnit?
        if volumeUnitInt == NilInt {
            volumeUnit = nil
        } else {
            volumeUnit = VolumeUnit(rawValue: volumeUnitInt)
        }

        let value = FoodValue(string: valueString)
        self.name = name
        self.quantity = quantity
        self.volumeUnit = volumeUnit
        self.value = value
    }
}

extension Array where Element == FoodSize {
    func sizeMatchingUnitSizeInFoodValue(_ foodValue: FoodValue) -> FoodSize? {
        first(where: { $0.id == foodValue.sizeID })
    }
}

//MARK: - Raw Value

extension FoodSize {
    var rawValue: FoodSizeRaw {
        FoodSizeRaw(foodSize: self)
    }
}

struct LegacyFoodSize: Codable, Hashable {
    var name: String
    var volumePrefixExplicitUnit: VolumeUnit?
    var quantity: Double
    var value: LegacyFoodValue
}

extension FoodSize {
    var legacy: LegacyFoodSize {
        LegacyFoodSize(
            name: name,
            volumePrefixExplicitUnit: volumeUnit,
            quantity: quantity,
            value: value.legacy
        )
    }
    
    init(legacy: LegacyFoodSize) {
        self.init(
            quantity: legacy.quantity,
            name: legacy.name,
            volumeUnit: legacy.volumePrefixExplicitUnit,
            value: FoodValue(legacy: legacy.value)
        )
    }
}

struct FoodSizeRaw: Codable, Hashable {
    var name: String
    var prefixVolumeUnitValue: Int
    var quantity: Double
    var valueRaw: FoodValueRaw
    
    init(foodSize: FoodSize) {
        self.init(
            name: foodSize.name,
            prefixVolumeUnitValue: foodSize.volumeUnit?.rawValue ?? NilInt,
            quantity: foodSize.quantity,
            valueRaw: foodSize.value.rawValue
        )
    }
    
    var foodSize: FoodSize {
        FoodSize(
            quantity: quantity,
            name: name,
            volumeUnit: prefixVolumeUnit,
            value: value
        )
    }
    
    init(
        name: String,
        prefixVolumeUnitValue: Int,
        quantity: Double,
        valueRaw: FoodValueRaw
    ) {
        self.name = name
        self.prefixVolumeUnitValue = prefixVolumeUnitValue
        self.quantity = quantity
        self.valueRaw = valueRaw
    }
    
    var prefixVolumeUnit: VolumeUnit? {
        get {
            guard prefixVolumeUnitValue != NilInt else { return nil }
            return VolumeUnit(rawValue: prefixVolumeUnitValue)
        }
        set {
            if let newValue {
                prefixVolumeUnitValue = newValue.rawValue
            } else {
                prefixVolumeUnitValue = NilInt
            }
        }
    }

    var value: FoodValue {
        get {
            valueRaw.foodValue
        }
        set {
            self.valueRaw = newValue.rawValue
        }
    }
}
