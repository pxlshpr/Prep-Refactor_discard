import Foundation
import CoreData

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
    
    var lastUsedAt: Date?
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
        lastUsedAt: Date? = nil,
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
        self.lastUsedAt = lastUsedAt
        self.updatedAt = updatedAt
        self.createdAt = createdAt
    }
}

extension Food {
    init(_ entity: FoodEntity2) {
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
            lastUsedAt: entity.lastUsedAt,
            updatedAt: entity.updatedAt!,
            createdAt: entity.createdAt!
        )
    }
}

extension Food {
    
    var foodName: String {
        var name = "\(emoji) \(name)"
        if let detail {
            name += ", \(detail)"
        }
        if let brand {
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
