//import Foundation
//import SwiftData
//
//import FoodDataTypes
//
//@Model
//class FoodEntity {
//    
//    let uuid: String
//    
//    var emoji: String
//    
//    var name: String
//    var detail: String?
//    var brand: String?
//    
//    var lowercasedName: String
//    var lowercasedDetail: String
//    var lowercasedBrand: String
//    
//    var amountRaw: FoodValueRaw
//    var servingRaw: FoodValueRaw
//    
//    var energy: Double
//    var carb: Double
//    var protein: Double
//    var fat: Double
//    var microsString: String?
//    
//    var sizesString: String?
//    var densityRaw: FoodDensityRaw
//    
//    var linkURL: String?
//    var imageIDs: [String]
//    var barcodes: [String]
//    
//    var numberOfTimesConsumedGlobally: Int
//    var numberOfTimesConsumed: Int
//    var lastUsedAt: Double?
//    var firstUsedAt: Double?
//    
//    /// Enum Value Backers
//    var typeValue: Int
//    var publishStatusValue: Int?
//    var datasetValue: Int?
//    var energyUnitValue: Int
//
//    var updatedAt: Double
//    
////    @Relationship(.cascade, inverse: \FoodItemEntity.optionalFood) var foodItems: [FoodItemEntity]
//    //    let childrenFoods: [FoodEntity]? //TODO: Use compact version here if we'll get cyclical errors
//    //    let ingredientItems: [IngredientItem]?
//    
//    init() {
//        uuid = UUID().uuidString
//        emoji = ""
//        name = ""
//        detail = nil
//        brand = nil
//        lowercasedName = ""
//        lowercasedDetail = ""
//        lowercasedBrand = ""
//        amountRaw = FoodValueRaw.NilValue
//        servingRaw = FoodValueRaw.NilValue
//        energy = 0
//        carb = 0
//        protein = 0
//        fat = 0
//        microsString = nil
//        sizesString = nil
//        densityRaw = FoodDensityRaw.NilValue
//        linkURL = nil
//        imageIDs = []
//        barcodes = []
//        numberOfTimesConsumedGlobally = 0
//        numberOfTimesConsumed = 0
//        lastUsedAt = nil
//        firstUsedAt = nil
//        typeValue = FoodType.food.rawValue
//        publishStatusValue = nil
//        datasetValue = nil
//        energyUnitValue = EnergyUnit.kcal.rawValue
//        updatedAt = Date.now.timeIntervalSince1970
////        foodItems = []
//    }
//    
//    init(
//        uuid: String,
//        type: FoodType,
//        name: String,
//        emoji: String,
//        detail: String? = nil,
//        brand: String? = nil,
//        numberOfTimesConsumedGlobally: Int,
//        numberOfTimesConsumed: Int,
//        lastUsedAt: Double?,
//        firstUsedAt: Double?,
//        info: LegacyFoodInfo,
//        publishStatus: PublishStatus?,
//        dataset: FoodDataset?,
//        barcodes: [String]?,
//        updatedAt: Double,
//        foodItems: [FoodItemEntity] = []
//    ) {
//        self.uuid = uuid
//        self.typeValue = type.rawValue
//        
//        self.emoji = emoji
//        
//        self.name = name
//        self.detail = detail
//        self.brand = brand
//        
//        self.lowercasedName = name.lowercased()
//        self.lowercasedDetail = detail?.lowercased() ?? ""
//        self.lowercasedBrand = brand?.lowercased() ?? ""
//        
//        self.numberOfTimesConsumedGlobally = numberOfTimesConsumedGlobally
//        self.numberOfTimesConsumed = numberOfTimesConsumed
//        self.lastUsedAt = lastUsedAt
//        self.firstUsedAt = firstUsedAt
//        
//        self.amountRaw = info.amount.foodValue.rawValue
//        self.servingRaw = info.serving?.foodValue.rawValue ?? .NilValue
//        
//        self.energy = info.nutrients.energyInKcal
//        self.energyUnitValue = EnergyUnit.kcal.rawValue
//        self.carb = info.nutrients.carb
//        self.protein = info.nutrients.protein
//        self.fat = info.nutrients.fat
//        
//        self.micros = info.nutrients.micros.map { FoodNutrient($0) }
//        
//        self.sizes = info.sizes.map { FoodSize(legacy: $0)}
//        self.density = info.density?.density
//        self.linkURL = info.prefilledUrl ?? info.linkUrl
//        self.imageIDs = info.imageIds?.map { $0.uuidString } ?? []
//        
//        self.barcodes = info.barcodes.map { $0.payload }
//        
//        self.updatedAt = updatedAt
////        self.foodItems = foodItems
//        
//        if let dataset {
//            self.datasetValue = dataset.rawValue
//        } else {
//            self.datasetValue = nil
//        }
//        
//        if let publishStatus {
//            self.publishStatusValue = publishStatus.rawValue
//        } else {
//            self.publishStatusValue = nil
//        }
//    }
//}
//
////MARK: Structs
//
//extension FoodEntity {
//    
//    var amount: FoodValue {
//        get { amountRaw.foodValue }
//        set { amountRaw = newValue.rawValue }
//    }
//    
//    var serving: FoodValue? {
//        get {
//            guard servingRaw != .NilValue else { return nil }
//            return servingRaw.foodValue
//        }
//        set {
//            if let newValue {
//                servingRaw = newValue.rawValue
//            } else {
//                servingRaw = .NilValue
//            }
//        }
//    }
//    
//    var sizes: [FoodSize] {
//        get {
//            guard let sizesString else { return [] }
//            return sizesString
//                .components(separatedBy: FoodSize.ArraySeparator)
//                .map { FoodSize(string: $0) }
//        }
//        set {
//            guard !newValue.isEmpty else {
//                sizesString = nil
//                return
//            }
//            sizesString = newValue
//                .map { $0.asString }
//                .joined(separator: FoodSize.ArraySeparator)
//        }
//    }
//    
//    var micros: [FoodNutrient] {
//        get {
//            guard let microsString else { return [] }
//            return microsString
//                .components(separatedBy: FoodNutrient.ArraySeparator)
//                .map { FoodNutrient(string: $0) }
//        }
//        set {
//            guard !newValue.isEmpty else {
//                microsString = nil
//                return
//            }
//            microsString = newValue
//                .map { $0.asString }
//                .joined(separator: FoodNutrient.ArraySeparator)
//        }
//    }
//    
//    var density: FoodDensity? {
//        get {
//            guard densityRaw != .NilValue else { return nil }
//            return densityRaw.foodDensity
//        }
//        set {
//            if let newValue {
//                densityRaw = newValue.rawValue
//            } else {
//                densityRaw = .NilValue
//            }
//        }
//    }
//}
//
////MARK: Enums
//
//extension FoodEntity {
//    
//    var type: FoodType {
//        get { FoodType(rawValue: typeValue) ?? .food }
//        set { typeValue = newValue.rawValue }
//    }
//    
//    var energyUnit: EnergyUnit {
//        get { EnergyUnit(rawValue: energyUnitValue) ?? .kcal }
//        set { energyUnitValue = newValue.rawValue }
//    }
//    
//    var dataset: FoodDataset? {
//        get {
//            guard let datasetValue else { return nil }
//            return FoodDataset(rawValue: datasetValue)
//        }
//        set {
//            if let newValue {
//                datasetValue = newValue.rawValue
//            } else {
//                datasetValue = nil
//            }
//        }
//    }
//    
//    var publishStatus: PublishStatus? {
//        get {
//            guard let publishStatusValue else { return nil }
//            return PublishStatus(rawValue: publishStatusValue)
//        }
//        set {
//            if let newValue {
//                publishStatusValue = newValue.rawValue
//            } else {
//                publishStatusValue = nil
//            }
//        }
//    }
//}
//
////MARK: - Form Helpers
//extension FoodEntity {
//    var isPublished: Bool {
//        switch publishStatus {
//        case .hidden, .rejected, .none: false
//        case .pendingReview, .verified: true
//        }
//    }
//}
