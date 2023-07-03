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
        
//        guard let meal = try! MealEntity2.object(with: UUID(uuidString: "F7C3C6E6-CC69-467A-82AD-066578156688")!, in: viewContext) else {
//            fatalError()
//        }
//        
//        print("We here")
        
        
        
//        guard let e = try! MealEntity2.object(
//            with: UUID(uuidString: "F7C3C6E6-CC69-467A-82AD-066578156688")!,
//            in: viewContext
//        ) else {
//            logger.error("Failed to find MealEntity with id: F7C3C6E6-CC69-467A-82AD-066578156688")
//            fatalError()
//        }
        
        Task {
            let start = CFAbsoluteTimeGetCurrent()
            await run("Days", populateDays_legacy)
            await run("Meals", populateMeals_legacy)
//            await run("Preset Foods", populatePresetFoods)
            await run("Preset Foods", populatePresetFoods1)
            await run("Preset Foods", populatePresetFoods2)
            await run("Preset Foods", populatePresetFoods3)
            await run("Preset Foods", populatePresetFoods4)
            await run("Preset Foods", populatePresetFoods5)
            await run("Preset Foods", populatePresetFoods6)
            await run("Preset Foods", populatePresetFoods7)
            await run("User Foods", populateUserFoods_legacy)
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
        let days = DayEntity2.countAll(in: viewContext)
        let meals = MealEntity2.countAll(in: viewContext)
        let foods = FoodEntity2.countAll(in: viewContext)
        let foodItems = FoodItemEntity2.countAll(in: viewContext)

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
    
    func populateDays(_ context: NSManagedObjectContext) {
        let url = Bundle.main.url(forResource: "days", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyDay].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) days…")

        /// For-Loop
//        for legacy in legacyObjects {
//            let entity = DayEntity2(context, legacy)
//            context.insert(entity)
//            logger.debug("Inserted Day: \(legacy.calendarDayString, privacy: .public)")
//        }
        
        func createBatchInsertRequest() -> NSBatchInsertRequest {
            /// Create an iterator for raw data
            var iterator = legacyObjects.makeIterator()
            
            let request = NSBatchInsertRequest(entity: DayEntity2.entity()) { (obj: NSManagedObject) in
                /// Stop add item when itemListIterator return nil
                guard let legacy = iterator.next() else { return true }
                
                /// Convert obj to DayEntity type and fill data to obj
                if let cmo = obj as? DayEntity2 {
                    cmo.dateString = legacy.calendarDayString
                }
                logger.debug("Inserted Day: \(legacy.calendarDayString, privacy: .public)")

                /// Continue add item to batch insert request
                return false
            }
            return request
        }
        
        let request = createBatchInsertRequest()
        try! context.execute(request)
    }

    func populateMeals(_ context: NSManagedObjectContext) {
        let url = Bundle.main.url(forResource: "meals", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyMeal].self, from: data)

        let daysURL = Bundle.main.url(forResource: "days", withExtension: "json")!
        let daysData = try! Data(contentsOf: daysURL)
        let legacyDays = try! JSONDecoder().decode([LegacyDay].self, from: daysData)

        logger.info("Prepopulating \(legacyObjects.count) meals…")
        
        func createBatchInsertRequest() -> NSBatchInsertRequest {
            /// Create an iterator for raw data
            var iterator = legacyObjects.makeIterator()
            
            let request = NSBatchInsertRequest(entity: MealEntity2.entity()) { (obj: NSManagedObject) in
                /// Stop add item when itemListIterator return nil
                guard let legacy = iterator.next() else { return true }
                
                guard legacy.deletedAt == nil || legacy.deletedAt == 0 else {
                    logger.warning("Ignoring deleted Meal: \(legacy.id, privacy: .public)")
                    return false
                }
                
                /// Convert obj to DayEntity type and fill data to obj
                if let cmo = obj as? MealEntity2 {
                    cmo.id = UUID(uuidString: legacy.id)!
                    cmo.name = legacy.name
                    cmo.time = Date(timeIntervalSince1970: legacy.time)
//                    cmo.dayEntity = dayEntity
                }
                logger.debug("Inserted Meal: \(legacy.id, privacy: .public)")

                /// Continue add item to batch insert request
                return false
            }
            return request
        }
        
        let request = createBatchInsertRequest()
        try! context.execute(request)
        
        let meals = MealEntity2.objects(in: context)
        for meal in meals {
            guard let legacy = legacyObjects.first(where: { $0.id == meal.id!.uuidString }) else {
                fatalError()
            }
            guard let legacyDay = legacyDays.first(where: { $0.id == legacy.dayID }) else {
                fatalError()
            }
            let dateString = legacyDay.calendarDayString
            let predicate = NSPredicate(format: "dateString == %@", dateString)
            let dayEntity = DayEntity2.objects(for: predicate, in: context).first
            
            guard let dayEntity else {
                logger.error("Failed to find DayEntity with id: \(legacy.dayID, privacy: .public)")
                fatalError()
            }
            meal.dayEntity = dayEntity
            logger.debug("Attached meal: \(meal.id!.uuidString, privacy: .public) to day: \(dayEntity.dateString!, privacy: .public)")
        }
    }
    
    func populatePresetFoods(_ context: NSManagedObjectContext) {
        let url = Bundle.main.url(forResource: "presetFoods", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyPresetFood].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) preset foods…")

//        for legacy in legacyObjects {
//            let entity = FoodEntity2(context, legacy)
//            context.insert(entity)
//            logger.debug("Inserted Preset Food: \(legacy.description, privacy: .public)")
//        }
        
        func createBatchInsertRequest() -> NSBatchInsertRequest {
            /// Create an iterator for raw data
            var iterator = legacyObjects.makeIterator()
            
            let request = NSBatchInsertRequest(entity: FoodEntity2.entity()) { (obj: NSManagedObject) in
                /// Stop add item when itemListIterator return nil
                guard let legacy = iterator.next() else { return true }
                
                /// Convert obj to DayEntity type and fill data to obj
                if let cmo = obj as? FoodEntity2 {
                    cmo.fill(legacy)
                }
                logger.debug("Inserted Preset Food: \(legacy.description, privacy: .public)")

                /// Continue add item to batch insert request
                return false
            }
            return request
        }
        
        let request = createBatchInsertRequest()
        try! context.execute(request)
    }
    
    func populateUserFoods(_ context: NSManagedObjectContext) {
        let url = Bundle.main.url(forResource: "foods", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyUserFood].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) user foods…")

//        for legacy in legacyObjects {
//            guard legacy.deletedAt == nil || legacy.deletedAt == 0 else {
//                logger.warning("Ignoring deleted User Food: \(legacy.description, privacy: .public)")
//                continue
//            }
//            let entity = FoodEntity2(context, legacy)
//            context.insert(entity)
//            logger.debug("Inserted User Food: \(legacy.description, privacy: .public)")
//        }
        
        func createBatchInsertRequest() -> NSBatchInsertRequest {
            /// Create an iterator for raw data
            var iterator = legacyObjects.makeIterator()
            
            let request = NSBatchInsertRequest(entity: FoodEntity2.entity()) { (obj: NSManagedObject) in
                /// Stop add item when itemListIterator return nil
                guard let legacy = iterator.next() else { return true }
                
                /// Convert obj to DayEntity type and fill data to obj
                if let cmo = obj as? FoodEntity2 {
                    cmo.fill(legacy)
                }
                logger.debug("Inserted User Food: \(legacy.description, privacy: .public)")

                /// Continue add item to batch insert request
                return false
            }
            return request
        }
        
        let request = createBatchInsertRequest()
        try! context.execute(request)
    }
    
    func populateFoodItems(_ context: NSManagedObjectContext) {
        
        let url = Bundle.main.url(forResource: "foodItems", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyFoodItem].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) food items…")

//        for legacy in legacyObjects {
//
//            /// Ensure this isn't a deleted FoodItem
//            guard legacy.deletedAt == nil || legacy.deletedAt == 0 else {
//                logger.warning("Ignoring deleted Food Item: \(legacy.id, privacy: .public)")
//                continue
//            }
//
//            guard let foodEntity = try! FoodEntity2.object(
//                with: UUID(uuidString: legacy.foodID)!,
//                in: context
//            ) else {
//                logger.error("Failed to find FoodEntity with id: \(legacy.foodID, privacy: .public)")
//                fatalError()
//            }
//
//            guard let mealID = legacy.mealID else {
//                logger.error("Encountered FoodItem: \(legacy.id, privacy: .public) without mealID")
//                fatalError()
//            }
//            guard let mealEntity = try! MealEntity2.object(
//                with: UUID(uuidString: mealID)!,
//                in: context
//            ) else {
//                logger.error("Failed to find MealEntity with id: \(mealID, privacy: .public)")
//                fatalError()
//            }
//
//            let entity = FoodItemEntity2(context, legacy, foodEntity, mealEntity)
//            context.insert(entity)
//            
//            logger.debug("Inserted Food Item: \(legacy.id, privacy: .public)")
//        }
        
        func createBatchInsertRequest() -> NSBatchInsertRequest {
            /// Create an iterator for raw data
            var iterator = legacyObjects.makeIterator()
            
            let request = NSBatchInsertRequest(entity: FoodItemEntity2.entity()) { (obj: NSManagedObject) in
                /// Stop add item when itemListIterator return nil
                guard let legacy = iterator.next() else { return true }
                
                /// Convert obj to DayEntity type and fill data to obj
                if let cmo = obj as? FoodItemEntity2 {
                    cmo.fill(legacy)
                }
                logger.debug("Inserted Food Item: \(legacy.id, privacy: .public)")

                /// Continue add item to batch insert request
                return false
            }
            return request
        }
        
        let request = createBatchInsertRequest()
        try! context.execute(request)
    }
    
    func attachFoodItems(_ context: NSManagedObjectContext) {
        
        let url = Bundle.main.url(forResource: "foodItems", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyFoodItem].self, from: data)

        let foodItems = FoodItemEntity2.objects(in: context)
        for foodItem in foodItems {
            guard let legacy = legacyObjects.first(where: { $0.id == foodItem.id!.uuidString }) else {
                fatalError()
            }

            guard let foodEntity = FoodEntity2.object(
                with: UUID(uuidString: legacy.foodID)!,
                in: context
            ) else {
                logger.error("Failed to find FoodEntity with id: \(legacy.foodID, privacy: .public)")
                fatalError()
            }

            guard let mealID = legacy.mealID else {
                logger.error("Encountered FoodItem: \(legacy.id, privacy: .public) without mealID")
                fatalError()
            }
            guard let mealEntity = MealEntity2.object(
                with: UUID(uuidString: mealID)!,
                in: context
            ) else {
                logger.error("Failed to find MealEntity with id: \(mealID, privacy: .public)")
                fatalError()
            }
            
            foodItem.foodEntity = foodEntity
            foodItem.mealEntity = mealEntity
            logger.debug("Attached food item: \(foodItem.id!.uuidString, privacy: .public)")
        }
    }


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
    
    func populateDays_legacy(_ context: NSManagedObjectContext) {
        let url = Bundle.main.url(forResource: "days", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyDay].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) days…")

        /// For-Loop
        for legacy in legacyObjects {
            let entity = DayEntity2(context, legacy)
            context.insert(entity)
            logger.debug("Inserted Day: \(legacy.calendarDayString, privacy: .public)")
        }
    }
    
    func populateMeals_legacy(_ context: NSManagedObjectContext) {
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
            let dayEntity = try! DayEntity2.objects(for: predicate, in: context).first
            
            guard let dayEntity else {
                logger.error("Failed to find DayEntity with id: \(legacy.dayID, privacy: .public)")
                fatalError()
            }

            let entity = MealEntity2(context, legacy, dayEntity)
            context.insert(entity)
            logger.debug("Inserted Meal: \(legacy.id, privacy: .public)")

        }
    }
    
    func populatePresetFoods1(_ context: NSManagedObjectContext) {
        populatePresetFoods_legacy(context, range: 0..<1000)
    }
    func populatePresetFoods2(_ context: NSManagedObjectContext) {
        populatePresetFoods_legacy(context, range: 1000..<2000)
    }
    func populatePresetFoods3(_ context: NSManagedObjectContext) {
        populatePresetFoods_legacy(context, range: 2000..<3000)
    }
    func populatePresetFoods4(_ context: NSManagedObjectContext) {
        populatePresetFoods_legacy(context, range: 3000..<4000)
    }
    func populatePresetFoods5(_ context: NSManagedObjectContext) {
        populatePresetFoods_legacy(context, range: 4000..<5000)
    }
    func populatePresetFoods6(_ context: NSManagedObjectContext) {
        populatePresetFoods_legacy(context, range: 5000..<6000)
    }
    func populatePresetFoods7(_ context: NSManagedObjectContext) {
        populatePresetFoods_legacy(context, range: 6000..<6775)
    }
    
    func populatePresetFoods_legacy(_ context: NSManagedObjectContext, range: Range<Int>) {
        let url = Bundle.main.url(forResource: "presetFoods", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyPresetFood].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) preset foods…")

        for legacy in legacyObjects[range] {

            let entity = FoodEntity2(context, legacy)
            context.insert(entity)
            
            logger.debug("Inserted Preset Food: \(legacy.description, privacy: .public)")
        }
    }
    
    func populateUserFoods_legacy(_ context: NSManagedObjectContext) {
        let url = Bundle.main.url(forResource: "foods", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyUserFood].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) user foods…")

        for legacy in legacyObjects {
            guard legacy.deletedAt == nil || legacy.deletedAt == 0 else {
                logger.warning("Ignoring deleted User Food: \(legacy.description, privacy: .public)")
                continue
            }
            let entity = FoodEntity2(context, legacy)
            context.insert(entity)
            logger.debug("Inserted User Food: \(legacy.description, privacy: .public)")
        }
    }
    
    func populateFoodItems1(_ context: NSManagedObjectContext) {
        populateFoodItems_legacy(context, range: 0..<200)
    }
    func populateFoodItems2(_ context: NSManagedObjectContext) {
        populateFoodItems_legacy(context, range: 200..<400)
    }
    func populateFoodItems3(_ context: NSManagedObjectContext) {
        populateFoodItems_legacy(context, range: 400..<600)
    }
    func populateFoodItems4(_ context: NSManagedObjectContext) {
        populateFoodItems_legacy(context, range: 600..<800)
    }
    func populateFoodItems5(_ context: NSManagedObjectContext) {
        populateFoodItems_legacy(context, range: 800..<1000)
    }
    func populateFoodItems6(_ context: NSManagedObjectContext) {
        populateFoodItems_legacy(context, range: 1000..<1279)
    }

    func populateFoodItems_legacy(_ context: NSManagedObjectContext, range: Range<Int>) {
        
        let url = Bundle.main.url(forResource: "foodItems", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let legacyObjects = try! JSONDecoder().decode([LegacyFoodItem].self, from: data)

        logger.info("Prepopulating \(legacyObjects.count) food items…")

        let mealEntities = MealEntity2.objects(in: context)
        let foodEntities = FoodEntity2.objects(in: context)
        
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

            let entity = FoodItemEntity2(context, legacy, foodEntity, mealEntity)
            context.insert(entity)
            
            logger.debug("Inserted Food Item: \(legacy.id, privacy: .public)")
        }
    }
}
