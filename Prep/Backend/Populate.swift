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
        
//        guard let meal = try! MealEntity.object(with: UUID(uuidString: "F7C3C6E6-CC69-467A-82AD-066578156688")!, in: viewContext) else {
//            fatalError()
//        }
//        
//        print("We here")
        
        
        
//        guard let e = try! MealEntity.object(
//            with: UUID(uuidString: "F7C3C6E6-CC69-467A-82AD-066578156688")!,
//            in: viewContext
//        ) else {
//            logger.error("Failed to find MealEntity with id: F7C3C6E6-CC69-467A-82AD-066578156688")
//            fatalError()
//        }
        
        Task {
            let start = CFAbsoluteTimeGetCurrent()
            await run("Days", populateDays)
            await run("Meals", populateMeals)
//            await run("Preset Foods", populatePresetFoods)
            await run("Preset Foods", populatePresetFoods1)
            await run("Preset Foods", populatePresetFoods2)
            await run("Preset Foods", populatePresetFoods3)
            await run("Preset Foods", populatePresetFoods4)
            await run("Preset Foods", populatePresetFoods5)
            await run("Preset Foods", populatePresetFoods6)
            await run("Preset Foods", populatePresetFoods7)
            await run("User Foods", populateUserFoods)
//            await run("Food Items", populateFoodItems)
            await run("Food Items", populateFoodItems1)
            await run("Food Items", populateFoodItems2)
            await run("Food Items", populateFoodItems3)
            await run("Food Items", populateFoodItems4)
            await run("Food Items", populateFoodItems5)
            await run("Food Items", populateFoodItems6)
            await run("setHasPopulated", setHasPopulated)
            logger.info("Populate took: \(CFAbsoluteTimeGetCurrent()-start)s")
        }
    }

    func run(_ name: String, _ function: @escaping (NSManagedObjectContext) -> ()) async {
        return await withCheckedContinuation { continuation in
            runPopulateFunction(name: name, function: function) {
                continuation.resume()
            }
        }
    }
    
    func runPopulateFunction(
        name: String,
        function: @escaping (NSManagedObjectContext) -> (),
        completion: @escaping () -> ()
    ) {
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
                        completion()
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
//        NotificationCenter.default.post(name: .didPopulate, object: nil)
        let days = DayEntity.countAll(in: viewContext)
        let meals = MealEntity.countAll(in: viewContext)
        let foods = FoodEntity.countAll(in: viewContext)
        let foodItems = FoodItemEntity.countAll(in: viewContext)

        logger.info("Populated: \(name, privacy: .public)")
        logger.info("==================")
        logger.info("Days: \(days)")
        logger.info("Meals: \(meals)")
        logger.info("Foods: \(foods)")
        logger.info("FoodItems: \(foodItems)")
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
        try setHasPopulated(context)
    }
    
}
extension CoreDataManager {

    func setHasPopulated(_ context: NSManagedObjectContext) {
        do {
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
        } catch {
            fatalError()
        }
    }
}

extension CoreDataManager {
    
    func populateDays(_ context: NSManagedObjectContext) {
        let url = Bundle.main.url(forResource: "days", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyDay].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) days…")

        /// For-Loop
        for legacy in legacyObjects {
            let entity = DayEntity(context, legacy)
            context.insert(entity)
            logger.debug("Inserted Day: \(legacy.calendarDayString, privacy: .public)")
        }
    }
    
    func populateMeals(_ context: NSManagedObjectContext) {
        let url = Bundle.main.url(forResource: "meals", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyMeal].self, from: data)

        let daysURL = Bundle.main.url(forResource: "days", withExtension: "json")!
        let daysData = try! Data(contentsOf: daysURL)
        let legacyDays = try! JSONDecoder().decode([LegacyDay].self, from: daysData)

        logger.info("Prepopulating \(legacyObjects.count) meals…")

        for legacy in legacyObjects {
            
            guard legacy.deletedAt == nil || legacy.deletedAt == 0 else {
                logger.warning("Ignoring deleted Meal: \(legacy.id, privacy: .public)")
                continue
            }
            
            guard let legacyDay = legacyDays.first(where: { $0.id == legacy.dayID }) else {
                fatalError()
            }
            let dateString = legacyDay.calendarDayString
            let predicate = NSPredicate(format: "dateString == %@", dateString)
            let dayEntity = try! DayEntity.objects(for: predicate, in: context).first
            
            guard let dayEntity else {
                logger.error("Failed to find DayEntity with id: \(legacy.dayID, privacy: .public)")
                fatalError()
            }

            let entity = MealEntity(context, legacy, dayEntity)
            context.insert(entity)
            logger.debug("Inserted Meal: \(legacy.id, privacy: .public)")

        }
    }
    
    func populatePresetFoods1(_ context: NSManagedObjectContext) {
        populatePresetFoods(context, range: 0..<1000)
    }
    func populatePresetFoods2(_ context: NSManagedObjectContext) {
        populatePresetFoods(context, range: 1000..<2000)
    }
    func populatePresetFoods3(_ context: NSManagedObjectContext) {
        populatePresetFoods(context, range: 2000..<3000)
    }
    func populatePresetFoods4(_ context: NSManagedObjectContext) {
        populatePresetFoods(context, range: 3000..<4000)
    }
    func populatePresetFoods5(_ context: NSManagedObjectContext) {
        populatePresetFoods(context, range: 4000..<5000)
    }
    func populatePresetFoods6(_ context: NSManagedObjectContext) {
        populatePresetFoods(context, range: 5000..<6000)
    }
    func populatePresetFoods7(_ context: NSManagedObjectContext) {
        populatePresetFoods(context, range: 6000..<6775)
    }
    
    func populatePresetFoods(_ context: NSManagedObjectContext, range: Range<Int>) {
        let url = Bundle.main.url(forResource: "presetFoods", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyPresetFood].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) preset foods…")

        for legacy in legacyObjects[range] {

            let entity = FoodEntity(context, legacy)
            context.insert(entity)
            
            logger.debug("Inserted Preset Food: \(legacy.description, privacy: .public)")
        }
    }
    
    func populateUserFoods(_ context: NSManagedObjectContext) {
        let url = Bundle.main.url(forResource: "foods", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyUserFood].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) user foods…")

        for legacy in legacyObjects {
            guard legacy.deletedAt == nil || legacy.deletedAt == 0 else {
                logger.warning("Ignoring deleted User Food: \(legacy.description, privacy: .public)")
                continue
            }
            let entity = FoodEntity(context, legacy)
            context.insert(entity)
            logger.debug("Inserted User Food: \(legacy.description, privacy: .public)")
        }
    }
    
    func populateFoodItems1(_ context: NSManagedObjectContext) {
        populateFoodItems(context, range: 0..<200)
    }
    func populateFoodItems2(_ context: NSManagedObjectContext) {
        populateFoodItems(context, range: 200..<400)
    }
    func populateFoodItems3(_ context: NSManagedObjectContext) {
        populateFoodItems(context, range: 400..<600)
    }
    func populateFoodItems4(_ context: NSManagedObjectContext) {
        populateFoodItems(context, range: 600..<800)
    }
    func populateFoodItems5(_ context: NSManagedObjectContext) {
        populateFoodItems(context, range: 800..<1000)
    }
    func populateFoodItems6(_ context: NSManagedObjectContext) {
        populateFoodItems(context, range: 1000..<1279)
    }

    func populateFoodItems(_ context: NSManagedObjectContext, range: Range<Int>) {
        
        let url = Bundle.main.url(forResource: "foodItems", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyFoodItem].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) food items…")

        let mealEntities = MealEntity.objects(in: context)
        let foodEntities = FoodEntity.objects(in: context)
        
        for legacy in legacyObjects[range] {

            /// Ensure this isn't a deleted FoodItem
            guard legacy.deletedAt == nil || legacy.deletedAt == 0 else {
                logger.warning("Ignoring deleted Food Item: \(legacy.id, privacy: .public)")
                continue
            }

            guard let foodEntity = foodEntities.first(where: { $0.id!.uuidString == legacy.foodID }) else {
                logger.error("Failed to find FoodEntity with id: \(legacy.foodID, privacy: .public)")
                fatalError()
            }

            guard let mealID = legacy.mealID else {
                logger.error("Encountered FoodItem: \(legacy.id, privacy: .public) without mealID")
                fatalError()
            }
            guard let mealEntity = mealEntities.first(where: { $0.id!.uuidString == mealID }) else {
                logger.error("Failed to find MealEntity with id: \(mealID, privacy: .public)")
                fatalError()
            }

            let entity = FoodItemEntity(context, legacy, foodEntity, mealEntity)
            context.insert(entity)
            
            logger.debug("Inserted Food Item: \(legacy.id, privacy: .public)")
        }
    }
}
