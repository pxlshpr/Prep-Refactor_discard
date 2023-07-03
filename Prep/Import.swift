import Foundation
//import SwiftData
import SwiftSugar
import OSLog

import FoodDataTypes

let importLogger = Logger(subsystem: "Database", category: "Import")

//@MainActor
//func importJSON(modelContext: ModelContext) {
// 
//    //MARK: Days
//    let daysURL = Bundle.main.url(forResource: "days", withExtension: "json")!
//    let daysData = try! Data(contentsOf: daysURL)
//    let flatDays = try! JSONDecoder().decode([LegacyDay].self, from: daysData)
//    
//    var days: [DayEntity] = []
//    for flatDay in flatDays {
//        let day = DayEntity(
//            uuid: flatDay.id,
//            calendarDayString: flatDay.calendarDayString
//        )
//        days.append(day)
//        importLogger.debug("Inserted day with: \(flatDay.calendarDayString, privacy: .public)")
//        modelContext.insert(day)
//    }
//    
//    //MARK: Meals
//    let mealsURL = Bundle.main.url(forResource: "meals", withExtension: "json")!
//    let mealsData = try! Data(contentsOf: mealsURL)
//    let flatMeals = try! JSONDecoder().decode([LegacyMeal].self, from: mealsData)
//    
//    var meals: [MealEntity] = []
//    for flatMeal in flatMeals {
//        guard let day = days.first(where: { $0.uuid == flatMeal.dayID }) else {
//            fatalError()
//        }
//        let meal = MealEntity(
//            uuid: flatMeal.id,
//            dayEntity: day,
//            name: flatMeal.name,
//            time: flatMeal.time
//        )
//        meals.append(meal)
//        modelContext.insert(meal)
//    }
//    
//    
//    //MARK: Foods
//    var foods: [FoodEntity] = []
//
//    let foodsURL = Bundle.main.url(forResource: "foods", withExtension: "json")!
//    let foodsData = try! Data(contentsOf: foodsURL)
//    let legacyFoods = try! JSONDecoder().decode([LegacyUserFood].self, from: foodsData)
//    
//    for legacyFood in legacyFoods {
//
//        importLogger.debug("Adding \(legacyFood.emoji, privacy: .public) \(legacyFood.name, privacy: .public) (\(legacyFood.id, privacy: .public))")
//
//        let food = FoodEntity(
//            uuid: legacyFood.id,
//            type: legacyFood.type,
//            name: legacyFood.name,
//            emoji: legacyFood.emoji,
//            detail: legacyFood.detail,
//            brand: legacyFood.brand,
//            numberOfTimesConsumedGlobally: legacyFood.numberOfTimesConsumedGlobally,
//            numberOfTimesConsumed: legacyFood.numberOfTimesConsumed,
//            lastUsedAt: legacyFood.lastUsedAt,
//            firstUsedAt: legacyFood.firstUsedAt,
//            info: legacyFood.info,
//            publishStatus: legacyFood.publishStatus,
//            dataset: legacyFood.dataset,
//            barcodes: legacyFood.barcodes,
//            updatedAt: legacyFood.updatedAt
//        )
//
//        foods.append(food)
//        modelContext.insert(food)
//        
//        do {
//            try modelContext.save()
//        } catch {
//            importLogger.error("Error saving: \(error)")
//        }
//    }
//
//    //MARK: PresetFoods
//    let presetFoodsURL = Bundle.main.url(forResource: "presetFoods", withExtension: "json")!
//    let presetFoodsData = try! Data(contentsOf: presetFoodsURL)
//    let presetFoods = try! JSONDecoder().decode([LegacyPresetFood].self, from: presetFoodsData)
//    
//    for presetFood in presetFoods {
//        
//        importLogger.debug("Adding \(presetFood.emoji, privacy: .public) \(presetFood.name, privacy: .public) (\(presetFood.id, privacy: .public))")
//        
//        let id = presetFood.id
//        
//        let food = FoodEntity(
//            uuid: id,
//            type: .food,
//            name: presetFood.name,
//            emoji: presetFood.emoji,
//            detail: presetFood.detail,
//            brand: presetFood.brand,
//            numberOfTimesConsumedGlobally: 0,
//            numberOfTimesConsumed: 0,
//            lastUsedAt: nil,
//            firstUsedAt: nil,
//            info: LegacyFoodInfo(
//                amount: presetFood.amount,
//                serving: presetFood.serving,
//                nutrients: presetFood.nutrients,
//                sizes: presetFood.sizes,
//                density: presetFood.density,
//                barcodes: []
//            ),
//            publishStatus: .verified,
//            dataset: presetFood.dataset,
//            barcodes: [],
//            updatedAt: presetFood.updatedAt
//        )
//        
//        foods.append(food)
//        modelContext.insert(food)
//        do {
//            try modelContext.save()
//        } catch {
//            importLogger.error("Error saving: \(error)")
//        }
//    }
//    
//    //MARK: FoodItems
//    let foodItemsURL = Bundle.main.url(forResource: "foodItems", withExtension: "json")!
//    let foodItemsData = try! Data(contentsOf: foodItemsURL)
//    let legacyFoodItems = try! JSONDecoder().decode([LegacyFoodItem].self, from: foodItemsData)
//    
//    var foodItems: [FoodItemEntity] = []
//    for legacyFoodItem in legacyFoodItems {
//        
//        importLogger.debug("Adding FoodItemEntity: \(legacyFoodItem.id, privacy: .public)")
//
//        guard legacyFoodItem.deletedAt == 0 else {
//            fatalError()
//        }
//        
//        guard let food = foods.first(where: { $0.uuid == legacyFoodItem.foodID }),
//              let meal = meals.first(where: { $0.uuid == legacyFoodItem.mealID })
//        else {
//            fatalError()
//        }
//        let foodItem = FoodItemEntity(
//            uuid: legacyFoodItem.id,
//            foodEntity: food,
//            mealEntity: meal,
//            amount: legacyFoodItem.amount.foodValue,
//            sortPosition: legacyFoodItem.sortPosition,
//            updatedAt: legacyFoodItem.updatedAt,
//            badgeWidth: legacyFoodItem.badgeWidth
//        )
//        
//        foodItems.append(foodItem)
//        modelContext.insert(foodItem)
//        
//        do {
//            try modelContext.save()
//        } catch {
//            importLogger.error("Error saving: \(error)")
//        }
//
//    }
//    
//    importLogger.info("Import Completed")
//}

//MARK: - Flat Models

struct LegacyDay: Identifiable, Hashable, Codable {
    let id: String
    let calendarDayString: String
    var goalSetID: String?
    var markedAsFasted: Bool
    var mealIDs: [String]
    var updatedAt: Double
}

struct LegacyMeal: Identifiable, Hashable, Codable {
    let id: String
    var dayID: String
    var name: String
    var time: Double
    var markedAsEatenAt: Double?
    var goalSetID: String?
    var goalWorkoutMinutes: Int?
    var badgeWidth: Double?
    var foodItemIDs: [String]
    var updatedAt: Double
    var deletedAt: Double?
}

struct LegacyPresetFood: Codable {
    var id: String
    var createdAt: Double
    var updatedAt: Double
    var deletedAt: Double?

    var name: String
    var emoji: String
    var amount: LegacyFoodValue
    var nutrients: LegacyFoodNutrients
    var sizes: [LegacyFoodSize]
    var numberOfTimesConsumed: Int32
    var dataset: FoodDataset

    var serving: LegacyFoodValue?
    var detail: String?
    var brand: String?
    var density: LegacyFoodDensity?
    var datasetFoodId: String?
    
    var barcodes: [LegacyBarcode]
    
    var description: String {
        "\(emoji) \(name) (\(id))"
    }
}

struct LegacyFoodNutrients: Codable, Hashable {
    var energyInKcal: Double
    var carb: Double
    var protein: Double
    var fat: Double
    var micros: [LegacyFoodNutrient]
}

struct LegacyFoodNutrient: Codable, Hashable {
    var nutrientType: Micro?
    var usdaType: Int?
    var value: Double
    var nutrientUnit: NutrientUnit
}

struct LegacyBarcode: Identifiable, Hashable, Codable {
    let id: UUID
    let payload: String
    let symbology: LegacyBarcodeSymbology
    
    init(id: UUID, payload: String, symbology: LegacyBarcodeSymbology) {
        self.id = id
        self.payload = payload
        self.symbology = symbology
    }
}

enum LegacyBarcodeSymbology: Int, Codable {
    case aztec = 1
    case code39
    case code39Checksum
    case code39FullASCII
    case code39FullASCIIChecksum
    case code93
    case code93i
    case code128
    case dataMatrix
    case ean8
    case ean13
    case i2of5
    case i2of5Checksum
    case itf14
    case pdf417
    case qr
    case upce
    case codabar
    case gs1DataBar
    case gs1DataBarExpanded
    case gs1DataBarLimited
    case microPDF417
    case microQR
}


struct LegacyUserFood: Identifiable, Hashable, Codable {
    let id: String
    let type: FoodType
    var name: String
    let emoji: String
    var detail: String?
    var brand: String?
    let numberOfTimesConsumedGlobally: Int
    let numberOfTimesConsumed: Int
    let lastUsedAt: Double?
    let firstUsedAt: Double?
    let info: LegacyFoodInfo
    
    let publishStatus: PublishStatus?
//    var jsonSyncStatus: SyncStatus
    let childrenFoods: [String]?
    let ingredientItems: [String]?
    
    let dataset: FoodDataset?
    
    let barcodes: [String]?
    
//    var syncStatus: SyncStatus
    var updatedAt: Double
    var deletedAt: Double?
    
    var description: String {
        "\(emoji) \(name) (\(id))"
    }
}

struct LegacyFoodItem: Identifiable, Hashable, Codable {
    let id: String
    
    let foodID: String
    let parentFoodID: String?
    var mealID: String?
    
    var amount: LegacyFoodValue
    var markedAsEatenAt: Double?
    var sortPosition: Int
    
//    var syncStatus: SyncStatus
    var updatedAt: Double
    var deletedAt: Double?
    
    var badgeWidth: Double?
}

struct LegacyFoodInfo: Codable, Hashable {
    var amount: LegacyFoodValue
    var serving: LegacyFoodValue?
    var nutrients: LegacyFoodNutrients
    var sizes: [LegacyFoodSize]
    var density: LegacyFoodDensity?
    
    var linkUrl: String?
    var prefilledUrl: String?
    var imageIds: [UUID]?
    var barcodes: [LegacyFoodBarcode]
    var spawnedUserFoodId: UUID?
    var spawnedPresetFoodId: UUID?
}

struct LegacyFoodBarcode: Codable, Hashable {
    var payload: String
    var symbology: LegacyBarcodeSymbology
    
    init(payload: String, symbology: LegacyBarcodeSymbology) {
        self.payload = payload
        self.symbology = symbology
    }
}
