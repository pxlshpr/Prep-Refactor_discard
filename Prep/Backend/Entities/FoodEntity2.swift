import Foundation
import CoreData

import FoodDataTypes

extension FoodEntity2: Entity {
    
    convenience init(context: NSManagedObjectContext, food: Food) {
        self.init(context: context)
        self.id = food.id
        
        self.emoji = food.emoji
        self.name = food.name
        self.detail = food.detail
        self.brand = food.brand
        
        self.amount = food.amount
        self.serving = food.serving
        
        self.energy = food.energy
        self.energyUnit = food.energyUnit
        self.carb = food.carb
        self.protein = food.protein
        self.fat = food.fat
        self.micros = food.micros
        self.sizes = food.sizes
        self.density = food.density
        self.url = food.url
        self.imageIDs = food.imageIDs
        self.barcodes = food.barcodes
        self.type = food.type
        self.publishStatus = food.publishStatus
        self.dataset = food.dataset
        self.lastUsedAt = food.lastUsedAt
        self.updatedAt = food.updatedAt
        self.createdAt = food.createdAt
    }
    
    func fill(_ legacy: LegacyPresetFood) {
        self.id = UUID(uuidString: legacy.id)
        self.emoji = legacy.emoji
        self.name = legacy.name
        self.detail = legacy.detail
        self.brand = legacy.brand
        self.amount = legacy.amount.foodValue
        self.serving = legacy.serving?.foodValue
        self.energy = legacy.nutrients.energyInKcal
        self.energyUnit = .kcal
        self.carb = legacy.nutrients.carb
        self.protein = legacy.nutrients.protein
        self.fat = legacy.nutrients.fat
        self.micros = legacy.nutrients.micros.map { FoodNutrient($0) }
        self.sizes = legacy.sizes.map { FoodSize(legacy: $0) }
        self.density = legacy.density?.density
        self.url = nil
        self.imageIDs = []
        self.barcodes = []
        self.type = .food
        self.publishStatus = nil
        self.dataset = legacy.dataset
        self.updatedAt = Date(timeIntervalSince1970: legacy.updatedAt)
        self.createdAt = Date(timeIntervalSince1970: legacy.createdAt)
    }
    
    convenience init(_ context: NSManagedObjectContext, _ legacy: LegacyPresetFood) {
        self.init(context: context)
        fill(legacy)
    }
    
    func fill(_ legacy: LegacyUserFood) {
        self.id = UUID(uuidString: legacy.id)!
        self.emoji = legacy.emoji
        self.name = legacy.name
        self.detail = legacy.detail
        self.brand = legacy.brand
        self.amount = legacy.info.amount.foodValue
        self.serving = legacy.info.serving?.foodValue
        self.energy = legacy.info.nutrients.energyInKcal
        self.energyUnit = .kcal
        self.carb = legacy.info.nutrients.carb
        self.protein = legacy.info.nutrients.protein
        self.fat = legacy.info.nutrients.fat
        self.micros = legacy.info.nutrients.micros.map { FoodNutrient($0) }
        self.sizes = legacy.info.sizes.map { FoodSize(legacy: $0) }
        self.density = legacy.info.density?.density
        self.url = nil
        self.imageIDs = []
        self.barcodes = []
        self.type = .food
        self.publishStatus = nil
        self.dataset = legacy.dataset
        if let lastUsedAt = legacy.lastUsedAt {
            self.lastUsedAt = Date(timeIntervalSince1970: lastUsedAt)
        }
        self.updatedAt = Date(timeIntervalSince1970: legacy.updatedAt)
        self.createdAt = Date(timeIntervalSince1970: legacy.updatedAt)
    }
    
    convenience init(_ context: NSManagedObjectContext, _ legacy: LegacyUserFood) {
        self.init(context: context)
        fill(legacy)
    }
}

extension FoodEntity2 {
    
    var imageIDs: [UUID] {
        get {
            guard let imageIDsString else { return [] }
            return imageIDsString
                .components(separatedBy: UUIDSeparator)
                .compactMap { UUID(uuidString: $0) }
        }
        set {
            self.imageIDsString = newValue
                .map { $0.uuidString }
                .joined(separator: UUIDSeparator)
        }
    }
    
    var barcodes: [String] {
        get {
            guard let barcodesString else { return [] }
            return barcodesString
                .components(separatedBy: BarcodesSeparator)
        }
        set {
            self.barcodesString = newValue
                .joined(separator: BarcodesSeparator)
        }
    }

    var amount: FoodValue {
        get {
            guard let amountData else {
                fatalError()
            }
            return try! JSONDecoder().decode(FoodValue.self, from: amountData)
        }
        set {
            self.amountData = try! JSONEncoder().encode(newValue)
        }
    }

    var micros: [FoodNutrient] {
        get {
            guard let microsData else { fatalError() }
            return try! JSONDecoder().decode([FoodNutrient].self, from: microsData)
        }
        set {
            self.microsData = try! JSONEncoder().encode(newValue)
        }
    }

    var sizes: [FoodSize] {
        get {
            guard let sizesData else { fatalError() }
            return try! JSONDecoder().decode([FoodSize].self, from: sizesData)
        }
        set {
            self.sizesData = try! JSONEncoder().encode(newValue)
        }
    }

    var serving: FoodValue? {
        get {
            guard let servingData else {
                return nil
            }
            return try! JSONDecoder().decode(FoodValue.self, from: servingData)
        }
        set {
            if let newValue {
                self.servingData = try! JSONEncoder().encode(newValue)
            } else {
                self.servingData = nil
            }
        }
    }
    
    var density: FoodDensity? {
        get {
            guard let densityData else { return nil }
            return try! JSONDecoder().decode(FoodDensity.self, from: densityData)
        }
        set {
            if let newValue {
                self.densityData = try! JSONEncoder().encode(newValue)
            } else {
                self.densityData = nil
            }
        }
    }

    var energyUnit: EnergyUnit {
        get {
            EnergyUnit(rawValue: Int(energyUnitValue)) ?? .kcal
        }
        set {
            energyUnitValue = Int16(newValue.rawValue)
        }
    }

    var type: FoodType {
        get {
            FoodType(rawValue: Int(typeValue)) ?? .food
        }
        set {
            typeValue = Int16(newValue.rawValue)
        }
    }

    var dataset: FoodDataset? {
        get {
            FoodDataset(rawValue: Int(datasetValue))
        }
        set {
            if let newValue {
                datasetValue = Int16(newValue.rawValue)
            } else {
                datasetValue = 0
            }
        }
    }

    var publishStatus: PublishStatus? {
        get {
            PublishStatus(rawValue: Int(publishStatusValue))
        }
        set {
            if let newValue {
                publishStatusValue = Int16(newValue.rawValue)
            } else {
                publishStatusValue = 0
            }
        }
    }
}
