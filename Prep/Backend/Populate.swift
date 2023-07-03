import Foundation
import CoreData
import SwiftSugar

import OSLog
private let logger = Logger(subsystem: "CoreDataManager", category: "Populate")

extension CoreDataManager {
    
    func populateIfNeeded() {
        do {
            let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
            request.fetchLimit = 1
            let hasPopulated = try viewContext
                .fetch(request)
                .first?
                .hasPopulated ?? false

            guard !hasPopulated else {
                logger.debug("Already Populated")
                return
            }
        } catch {
            logger.error("\(error.localizedDescription, privacy: .public)")
        }
        
        runPopulateFunction("Days", populateDays)
    }
    
    func runPopulateFunction(_ name: String, _ function: @escaping (NSManagedObjectContext) -> ()) {
        Task.detached(priority: .high) {
            let bgContext = self.newBackgroundContext()
            bgContext.mergePolicy = NSMergePolicy(merge: .rollbackMergePolicyType)
            await bgContext.perform {
                do {
                    function(bgContext)
//                    try self.populate(bgContext)
                    
                    let observer = NotificationCenter.default.addObserver(
                        forName: .NSManagedObjectContextDidSave,
                        object: bgContext,
                        queue: .main
                    ) { (notification) in
                        self.viewContext.mergeChanges(fromContextDidSave: notification)
                        self.didPopulate(name)
                    }
                    
                    try bgContext.performAndWait {
                        try bgContext.save()
                    }
                    NotificationCenter.default.removeObserver(observer)
                    
                } catch {
                    logger.error("Error: \(error)")
                }
            }
        }
    }
    
    func didPopulate(_ name: String) {
        do {
//            NotificationCenter.default.post(name: .didPopulate, object: nil)
            let days = try DayEntity2.countAll(in: viewContext)
            let meals = try MealEntity2.countAll(in: viewContext)
            let foods = try FoodEntity2.countAll(in: viewContext)
            let foodItems = try FoodItemEntity2.countAll(in: viewContext)

            logger.info("Populated: \(name, privacy: .public)")
            logger.info("==================")
            logger.info("Days: \(days)")
            logger.info("Meals: \(meals)")
            logger.info("Foods: \(foods)")
            logger.info("FoodItems: \(foodItems)")


        } catch {
            logger.error("Error printing summary: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func populate(_ context: NSManagedObjectContext) throws {

//        let dayEntities = populateDays(context)
//        try context.performAndWait { try context.save() }
//
//        let mealEntities = populateMeals(context, dayEntities)
//        try context.performAndWait { try context.save() }
//        
//        var foodEntities = populatePresetFoods(context)
//        try context.performAndWait { try context.save() }

//        foodEntities += populateUserFoods(context)
//        let _ = populateFoodItems(context, foodEntities: foodEntities, mealEntities: mealEntities)
//        try setHasPopulated(context)
    }
    
}
extension CoreDataManager {
    
    func populateDays(_ context: NSManagedObjectContext) {
        let url = Bundle.main.url(forResource: "days", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyDay].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) days…")

        for legacy in legacyObjects {
            let entity = DayEntity2(context, legacy)
            context.insert(entity)
            logger.debug("Inserted Day: \(legacy.calendarDayString, privacy: .public)")
        }
    }
    
    func populateDays(_ context: NSManagedObjectContext) -> [String: DayEntity2] {
        let url = Bundle.main.url(forResource: "days", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyDay].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) days…")

        var entities: [String: DayEntity2] = [:]
        for legacy in legacyObjects {
            let entity = DayEntity2(context, legacy)
            context.insert(entity)
            logger.debug("Inserted Day: \(legacy.calendarDayString, privacy: .public)")

            entities[legacy.id] = entity
            
        }
        return entities
    }
    
    func populateMeals(_ context: NSManagedObjectContext, _ dayEntities: [String: DayEntity2]) -> [MealEntity2] {
        let url = Bundle.main.url(forResource: "meals", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyMeal].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) meals…")

        var entities: [MealEntity2] = []
        for legacy in legacyObjects {
            
            guard legacy.deletedAt == nil || legacy.deletedAt == 0 else {
                logger.warning("Ignoring deleted Meal: \(legacy.id, privacy: .public)")
                continue
            }
            
            guard let dayEntity = dayEntities[legacy.dayID] else {
                logger.error("Failed to find DayEntity with id: \(legacy.dayID, privacy: .public)")
                fatalError()
            }

            let entity = MealEntity2(context, legacy, dayEntity)
            context.insert(entity)
            logger.debug("Inserted Meal: \(legacy.id, privacy: .public)")

            entities.append(entity)
        }
        return entities
    }
    
    func populatePresetFoods(_ context: NSManagedObjectContext) -> [FoodEntity2] {
        let url = Bundle.main.url(forResource: "presetFoods", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyPresetFood].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) preset foods…")

        var entities: [FoodEntity2] = []
        for legacy in legacyObjects {

            let entity = FoodEntity2(context, legacy)
            context.insert(entity)
            
            logger.debug("Inserted Legacy Food: \(legacy.description, privacy: .public)")

            entities.append(entity)
        }
        return entities
    }
    
    func populateUserFoods(_ context: NSManagedObjectContext) -> [FoodEntity2] {
        let url = Bundle.main.url(forResource: "foods", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyUserFood].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) user foods…")

        var entities: [FoodEntity2] = []
        for legacy in legacyObjects {

            guard legacy.deletedAt == nil || legacy.deletedAt == 0 else {
                logger.warning("Ignoring deleted User Food: \(legacy.description, privacy: .public)")
                continue
            }

            let entity = FoodEntity2(context, legacy)
            context.insert(entity)
            
            logger.debug("Inserted User Food: \(legacy.description, privacy: .public)")

            entities.append(entity)
        }
        return entities
    }
    
    func populateFoodItems(
        _ context: NSManagedObjectContext,
        foodEntities: [FoodEntity2],
        mealEntities: [MealEntity2]
    ) -> [FoodItemEntity2] {
        
        let url = Bundle.main.url(forResource: "foodItems", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyFoodItem].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) food items…")

        var entities: [FoodItemEntity2] = []
        for legacy in legacyObjects {

            guard legacy.deletedAt == nil || legacy.deletedAt == 0 else {
                logger.warning("Ignoring deleted Food Item: \(legacy.id, privacy: .public)")
                continue
            }

            guard let foodEntity = foodEntities.first(where: { $0.id?.uuidString == legacy.foodID }) else {
                logger.error("Failed to find FoodEntity with id: \(legacy.foodID, privacy: .public)")
                fatalError()
            }

            guard let mealID = legacy.mealID else {
                logger.error("Encountered FoodItem: \(legacy.id, privacy: .public) without mealID")
                fatalError()
            }
            guard let mealEntity = mealEntities.first(where: { $0.id?.uuidString == mealID }) else {
                logger.error("Failed to find MealEntity with id: \(mealID, privacy: .public)")
                fatalError()
            }

            let entity = FoodItemEntity2(context, legacy, foodEntity, mealEntity)
            context.insert(entity)
            
            logger.debug("Inserted Food Item: \(legacy.id, privacy: .public)")

            entities.append(entity)
        }
        return entities
    }


    func setHasPopulated(_ context: NSManagedObjectContext) throws {
        logger.debug("Setting hasPopulated...")
        let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
        request.fetchLimit = 1
        
        let settings: SettingsEntity
        if let fetched = try context.fetch(request).first {
            logger.debug("Fetched existing SettingsEntity")
            settings = fetched
        } else {
            logger.debug("Created new SettingsEntity")
            let new = SettingsEntity(context: context)
            settings = new
        }
        settings.hasPopulated = true
    }
}
