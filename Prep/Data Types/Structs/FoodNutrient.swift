import Foundation
import FoodDataTypes

struct FoodNutrient: Codable, Hashable {
    
    static let ArraySeparator = "¦"
    static let Separator = "_"
    
    /**
     This can only be `nil` for USDA imported nutrients that aren't yet supported (and must therefore have a `usdaType` if so).
     */
    var micro: Micro?
    
    /**
     This is used to store the id of a USDA nutrient.
     */
    var usdaType: Int?
    var value: Double
    var unit: NutrientUnit
}

extension FoodNutrient {
    
    init?(_ nutrientValue: NutrientValue) {
        guard let micro = nutrientValue.micro else { return nil }
        self.init(
            micro: micro,
            usdaType: nil,
            value: nutrientValue.value,
            unit: nutrientValue.unit
        )
    }
    
    init(_ legacy: LegacyFoodNutrient) {
        self.init(
            micro: legacy.nutrientType,
            usdaType: legacy.usdaType,
            value: legacy.value,
            unit: legacy.nutrientUnit
        )
    }
}

//MARK: - Raw Value

extension FoodNutrient {
    
    var asString: String {
        "\(micro?.rawValue ?? NilInt)"
        + "\(Self.Separator)\(usdaType ?? NilInt)"
        + "\(Self.Separator)\(value)"
        + "\(Self.Separator)\(unit.rawValue)"
    }
    
    init(string: String) {
        let components = string.components(separatedBy: Self.Separator)
        guard components.count == 4 else { fatalError() }
        
        guard let microInt = Int(components[0]) else { fatalError() }
        let micro: Micro?
        if microInt == NilInt {
            micro = nil
        } else {
            micro = Micro(rawValue: microInt)!
        }
        
        guard let usdaTypeInt = Int(components[1]) else { fatalError() }
        let usdaType: Int?
        if usdaTypeInt == NilInt {
            usdaType = nil
        } else {
            usdaType = usdaTypeInt
        }
        
        guard let value = Double(components[2]) else { fatalError() }
        
        guard let unitInt = Int(components[3]) else { fatalError() }
        guard let unit = NutrientUnit(rawValue: unitInt) else { fatalError() }
        
        self.micro = micro
        self.usdaType = usdaType
        self.value = value
        self.unit = unit
    }
    
    var rawValue: FoodNutrientRaw {
        FoodNutrientRaw(foodNutrient: self)
    }
}

struct FoodNutrientRaw: Codable, Hashable {
    var microValue: Int
    var usdaTypeValue: Int
    var value: Double
    var unitValue: Int
    
    init(foodNutrient: FoodNutrient) {
        self.init(
            microValue: foodNutrient.micro?.rawValue ?? NilInt,
            usdaTypeValue: foodNutrient.usdaType ?? NilInt,
            value: foodNutrient.value,
            unitValue: foodNutrient.unit.rawValue
        )
    }
    
    init(
        microValue: Int,
        usdaTypeValue: Int,
        value: Double,
        unitValue: Int
    ) {
        self.microValue = microValue
        self.usdaTypeValue = usdaTypeValue
        self.value = value
        self.unitValue = unitValue
    }
    
    var foodNutrient: FoodNutrient {
        FoodNutrient(
            micro: micro,
            usdaType: usdaType,
            value: value,
            unit: unit
        )
    }
    
    var micro: Micro? {
        get {
            guard microValue != NilInt else { return nil }
            return Micro(rawValue: microValue)
        }
        set {
            if let newValue {
                microValue = newValue.rawValue
            } else {
                microValue = NilInt
            }
        }
    }
    
    var unit: NutrientUnit {
        get {
            NutrientUnit(rawValue: unitValue) ?? .g
        }
        set {
            unitValue = newValue.rawValue
        }
    }
    
    var usdaType: Int? {
        get {
            usdaTypeValue == NilInt ? nil : usdaTypeValue
        }
        set {
            usdaTypeValue = newValue ?? NilInt
        }
    }
}
