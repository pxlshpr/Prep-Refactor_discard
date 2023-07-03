import Foundation
import CoreData

import FoodDataTypes

struct Food2: Identifiable, Codable, Hashable {
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
        id: UUID,
        emoji: String,
        name: String,
        detail: String? = nil,
        brand: String? = nil,
        amount: FoodValue,
        serving: FoodValue? = nil,
        energy: Double,
        energyUnit: EnergyUnit,
        carb: Double,
        protein: Double,
        fat: Double,
        micros: [FoodNutrient],
        sizes: [FoodSize],
        density: FoodDensity? = nil,
        url: String? = nil,
        imageIDs: [UUID],
        barcodes: [String],
        type: FoodType,
        publishStatus: PublishStatus? = nil,
        dataset: FoodDataset? = nil,
        lastUsedAt: Date? = nil,
        updatedAt: Date,
        createdAt: Date
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

extension Food2 {
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
