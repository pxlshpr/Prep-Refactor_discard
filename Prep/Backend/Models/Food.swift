import Foundation
import FoodDataTypes

struct Food: Identifiable, Codable, Hashable {
    let id: UUID
    
    var emoji: String
    var name: String
    var detail: String?
    var brand: String?
    
    var amount: FoodValue
    var serving: FoodValue?
    
    var energy: Double
    var energyUnit: EnergyUnit
    
    var carb: Double
    var protein: Double
    var fat: Double
    
    var micros: [FoodNutrient]
    
    var sizes: [FoodSize]
    var density: FoodDensity?
    
    var url: String?
    var imageIDs: [UUID]
    var barcodes: [String]
    
    let type: FoodType
    var publishStatus: PublishStatus?
    var dataset: FoodDataset?
    var datasetID: String?
    
    var lastUsedAt: Date?
    var lastAmount: FoodValue?

    var updatedAt: Date
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        emoji: String = String.randomFoodEmoji,
        name: String = "",
        detail: String? = nil,
        brand: String? = nil,
        amount: FoodValue = FoodValue(100, .weight(.g)),
        serving: FoodValue? = FoodValue(100, .weight(.g)),
        energy: Double = 0,
        energyUnit: EnergyUnit = .kcal,
        carb: Double = 0,
        protein: Double = 0,
        fat: Double = 0,
        micros: [FoodNutrient] = [],
        sizes: [FoodSize] = [],
        density: FoodDensity? = nil,
        url: String? = nil,
        imageIDs: [UUID] = [],
        barcodes: [String] = [],
        type: FoodType = .food,
        publishStatus: PublishStatus? = nil,
        dataset: FoodDataset? = nil,
        datasetID: String? = nil,
        lastUsedAt: Date? = nil,
        lastAmount: FoodValue? = nil,
        updatedAt: Date = Date.now,
        createdAt: Date = Date.now
    ) {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.detail = detail
        self.brand = brand
        self.amount = amount
        self.serving = serving
        self.energy = energy
        self.energyUnit = energyUnit
        self.carb = carb
        self.protein = protein
        self.fat = fat
        self.micros = micros
        self.sizes = sizes
        self.density = density
        self.url = url
        self.imageIDs = imageIDs
        self.barcodes = barcodes
        self.type = type
        self.publishStatus = publishStatus
        self.dataset = dataset
        self.datasetID = datasetID
        self.lastUsedAt = lastUsedAt
        self.lastAmount = lastAmount
        self.updatedAt = updatedAt
        self.createdAt = createdAt
    }
}

extension Food {
    init(_ entity: FoodEntity) {
        self.init(
            id: entity.id!,
            emoji: entity.emoji!,
            name: entity.name!,
            detail: entity.detail,
            brand: entity.brand,
            amount: entity.amount,
            serving: entity.serving,
            energy: entity.energy,
            energyUnit: entity.energyUnit,
            carb: entity.carb,
            protein: entity.protein,
            fat: entity.fat,
            micros: entity.micros,
            sizes: entity.sizes,
            density: entity.density,
            url: entity.url,
            imageIDs: entity.imageIDs,
            barcodes: entity.barcodes,
            type: entity.type,
            publishStatus: entity.publishStatus,
            dataset: entity.dataset,
            datasetID: entity.datasetID,
            lastUsedAt: entity.lastUsedAt,
            lastAmount: entity.lastAmount,
            updatedAt: entity.updatedAt!,
            createdAt: entity.createdAt!
        )
    }
}

extension Food {
    
    var foodName: String {
        var name = "\(emoji) \(name)"
        if let detail, !detail.isEmpty {
            name += ", \(detail)"
        }
        if let brand, !brand.isEmpty {
            name += ", \(brand)"
        }
        return name
    }

    var macrosChartData: [MacroValue] {
        [
            MacroValue(macro: .carb, value: carb),
            MacroValue(macro: .fat, value: fat),
            MacroValue(macro: .protein, value: protein)
        ]
    }

    func distanceOfSearchText(_ text: String) -> Int {
        
        let text = text.lowercased()
        
//        logger.debug("Getting distance within \(self.description, privacy: .public)")
        var distance: Int = Int.max
        if let index = name.lowercased().index(of: text) {
            distance = index
        }
        
        if let detail,
           let index = detail.lowercased().index(of: text),
           index < distance {
            distance = index + 100
        }
        if let brand,
           let index = brand.lowercased().index(of: brand),
           index < distance {
            distance = index + 200
        }
        
//        let logger = Logger(subsystem: "Search", category: "Text Distance")
//        logger.debug("Distance of \(text, privacy: .public) within \(self.description, privacy: .public) = \(distance)")
        
        return distance
    }
    
    func ratioOfSearchText(_ text: String) -> Double {
        
        let text = text.lowercased()
        
        var max: Double = 0
        if let ratio = name.lowercased().ratio(of: text) {
            max = ratio
        }
        
        if let detail,
           let ratio = detail.lowercased().ratio(of: text),
           ratio > max {
            max = ratio
        }
        if let brand,
           let ratio = brand.lowercased().ratio(of: brand),
           ratio > max {
            max = ratio
        }
        
        return max
    }
    
    var totalCount: Int {
        var count = name.count
        count += detail?.count ?? 0
        count += brand?.count ?? 0
        return count
    }
}

extension Food {
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
}

extension Food {
    var formSizes: [FormSize] {
        sizes.compactMap { foodSize in
            FormSize(foodSize: foodSize, in: sizes)
        }
    }
}

extension Food {
    var canBeMeasuredInServings: Bool {
        amount.unitType == .serving
    }
    
    var defaultAmounts: [FoodValue] {
        var amounts: [FoodValue] = []
        if canBeMeasuredInServings {
            amounts.append(.init(1, .serving))
        }
        if canBeMeasuredInWeight {
            amounts.append(.init(100, .weight(.g)))
        }
        if canBeMeasuredInVolume {
            amounts.append(.init(1, .volume(.cupMetric)))
        }
        for size in self.formSizes {
            let amount: FoodValue
            if size.isVolumePrefixed, let volume = size.volumeUnit {
                amount = .init(1, .size(size, volume))
            } else {
                amount = .init(1, .size(size, nil))
            }
            amounts.append(amount)
        }
        return amounts
    }
}
