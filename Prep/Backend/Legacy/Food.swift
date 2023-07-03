import Foundation
import FoodDataTypes

struct Food: Identifiable, Hashable {
    
    var id: String = UUID().uuidString
    
    var emoji: String = String.randomFoodEmoji
    var name: String = ""
    var detail: String? = nil
    var brand: String? = nil
    
    var amount: FoodValue = FoodValue(100, .weight(.g))
    var serving: FoodValue? = FoodValue(100, .weight(.g))
    
    var energy: Double = 0
    var energyUnit: EnergyUnit = .kcal
    
    var carb: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    
    var micros: [FoodNutrient] = []
    
    var sizes: [FoodSize] = []
    var density: FoodDensity? = nil
    
    var linkURL: String? = nil
    var imageIDs: [String] = []
    var barcodes: [String] = []
    
    var numberOfTimesConsumedGlobally: Int = 0
    var numberOfTimesConsumed: Int = 0
    var lastUsedAt: Double? = nil
    var firstUsedAt: Double? = nil
    
    var type: FoodType = .food
    var publishStatus: PublishStatus? = nil
    var dataset: FoodDataset? = nil
    
    var updatedAt: Double = 0
    
    init() { }
    
    init(_ entity: FoodEntity) {
        self.init()
        self.id = entity.uuid
        self.emoji = entity.emoji
        self.name = entity.name
        self.detail = entity.detail
        self.brand = entity.brand
        self.amount = entity.amount
        self.serving = entity.serving
        self.energy = entity.energy
        self.energyUnit = entity.energyUnit
        self.carb = entity.carb
        self.protein = entity.protein
        self.fat = entity.fat
        self.micros = entity.micros
        self.sizes = entity.sizes
        self.density = entity.density
        self.linkURL = entity.linkURL
        self.imageIDs = entity.imageIDs
        self.barcodes = entity.barcodes
        self.numberOfTimesConsumedGlobally = entity.numberOfTimesConsumedGlobally
        self.numberOfTimesConsumed = entity.numberOfTimesConsumed
        self.lastUsedAt = entity.lastUsedAt
        self.firstUsedAt = entity.firstUsedAt
        self.type = entity.type
        self.publishStatus = entity.publishStatus
        self.dataset = entity.dataset
        self.updatedAt = entity.updatedAt
    }
}

extension FoodEntity {
    var food: Food {
        Food(self)
    }
}

extension Food2 {
    var isPublished: Bool {
        switch publishStatus {
        case .hidden, .rejected, .none: false
        case .pendingReview, .verified: true
        }
    }
}

extension Food {

    func quantity(for amount: FoodValue) -> FoodQuantity? {
        guard let unit = FoodQuantity.Unit(foodValue: amount, in: self) else { return nil }
        return FoodQuantity(value: amount.value, unit: unit, food: self)
    }
    
    var foodQuantitySizes: [FoodQuantity.Size] {
        sizes.compactMap { foodSize in
            FoodQuantity.Size(foodSize: foodSize, in: self)
        }
    }

    func possibleUnits(
        without unit: FoodQuantity.Unit,
        using volumeUnits: VolumeUnits) -> [FoodQuantity.Unit]
    {
        possibleUnits(using: volumeUnits).filter {
            /// If the units are both sizes—compare the sizes alone to exclude any potential different volume prefixes
            if let possibleSize = $0.size, let size = unit.size {
                return possibleSize.id != size.id
            } else {
                return $0 != unit
            }
        }
    }
    
    func possibleUnits(using volumeUnits: VolumeUnits) -> [FoodQuantity.Unit] {
        var units: [FoodQuantity.Unit] = []
        for size in foodQuantitySizes {
            var volumePrefix: VolumeUnit? = nil
            if let volumeUnit = size.volumeUnit {
                volumePrefix = volumeUnits.volumeUnit(for: volumeUnit.type)
            }
            units.append(.size(size, volumePrefix))
        }
        if serving != nil {
            units.append(.serving)
        }
        if canBeMeasuredInWeight {
            units.append(contentsOf: WeightUnit.allCases.map { .weight($0) })
        }
        let volumeTypes: [VolumeUnitType] = [.mL, .liter, .cup, .fluidOunce, .tablespoon, .teaspoon]
        if canBeMeasuredInVolume {
            units.append(contentsOf: volumeTypes.map { .volume(volumeUnits.volumeUnit(for: $0)) })
        }
        return units
    }
}

extension Food {
    var canBeMeasuredInWeight: Bool {
        if density != nil {
            return true
        }
        
        if amount.isWeightBased(in: self) {
            return true
        }
        if let serving, serving.isWeightBased(in: self) {
            return true
        }
        for size in formSizes {
            if size.isWeightBased {
                return true
            }
        }
        return false
    }
    
    var canBeMeasuredInVolume: Bool {
        if density != nil {
            return true
        }
        
        if amount.isVolumeBased(in: self) {
            return true
        }
        if let serving, serving.isVolumeBased(in: self) {
            return true
        }
        
        //TODO: Copy `isVolumeBased` etc to FoodQuantity.Size and use foodQuantitySizes here instead (and remove formSizes)
        for size in formSizes {
            if size.isVolumeBased {
                return true
            }
        }
        return false
    }
    
    var onlySupportsWeights: Bool {
        canBeMeasuredInWeight
        && !canBeMeasuredInVolume
        && serving == nil
        && sizes.isEmpty
    }
    
    var onlySupportsVolumes: Bool {
        canBeMeasuredInVolume
        && !canBeMeasuredInWeight
        && serving == nil
        && sizes.isEmpty
    }

    var onlySupportsServing: Bool {
        serving != nil
        && !canBeMeasuredInVolume
        && !canBeMeasuredInWeight
        && sizes.isEmpty
    }
}

extension Food {
    func value(for nutrient: Nutrient) -> NutrientValue? {
        switch nutrient {
        case .energy:
            return NutrientValue(value: energy, energyUnit: energyUnit)
        case .macro(let macro):
            return switch macro {
            case .carb:     NutrientValue(macro: .carb, value: carb)
            case .fat:      NutrientValue(macro: .fat, value: fat)
            case .protein:  NutrientValue(macro: .protein, value: protein)
            }
        case .micro(let micro):
            guard let nutrient = micros.first(where: { $0.micro == micro }) else {
                return nil
            }
            return NutrientValue(nutrient)
        }
    }
}
extension Food {
    
    var primaryMacro: Macro {
        let carbCalories = carb * KcalsPerGramOfCarb
        let fatCalories = fat * KcalsPerGramOfFat
        let proteinCalories = protein * KcalsPerGramOfProtein
        if carbCalories > fatCalories && carbCalories > proteinCalories {
            return .carb
        }
        if fatCalories > carbCalories && fatCalories > proteinCalories {
            return .fat
        }
        return .protein
    }
    
    var macrosChartData: [MacroValue] {
        [
            MacroValue(macro: .carb, value: carb),
            MacroValue(macro: .fat, value: fat),
            MacroValue(macro: .protein, value: protein)
        ]
    }
}

extension Food {
    var formSizes: [FormSize] {
        sizes.compactMap { foodSize in
            FormSize(foodSize: foodSize, in: sizes)
        }
    }
}
