//import Foundation
//import SwiftData
//import OSLog
//
//private let logger = Logger(subsystem: "MealStore", category: "")
//
//actor FetchMealStore: ModelActor {
//    
//    static let shared = FetchMealStore()
//    
//    let executor: any ModelExecutor
//    init() {
//        let container = try! ModelContainer(for: allModelTypes)
//        let context = ModelContext(container)
//        let executor = DefaultModelExecutor(context: context)
//        self.executor = executor
//    }
//    
//    func meals(date: Date) throws -> [Meal] {
//        fetchMeals(on: date, context: context)
//    }
//}
//
//actor MealStore: ModelActor {
//
//    static let shared = MealStore()
//    
//    let executor: any ModelExecutor
//    init() {
//        let container = try! ModelContainer(for: allModelTypes)
//        let context = ModelContext(container)
//        let executor = DefaultModelExecutor(context: context)
//        self.executor = executor
//    }
//    
//    func create(name: String, time: Date, date: Date) throws -> Meal {
//        
//        let calendarDayString = date.calendarDayString
//        let descriptor = FetchDescriptor(predicate: #Predicate<DayEntity> {
//            $0.calendarDayString == calendarDayString
//        })
//
//        logger.debug("Fetching day with calendarDayString: \(calendarDayString)")
//        let days = try context.fetch(descriptor)
//        guard days.count <= 1 else {
//            fatalError("Duplicate days for: \(date.calendarDayString)")
//        }
//        
//        let fetchedDay = days.first
//        let dayEntity: DayEntity
//        if let fetchedDay {
//            logger.info("Day was fetched")
//            dayEntity = fetchedDay
//        } else {
//            logger.info("Day wasn't fetched, creating ...")
//            let newDay = DayEntity(calendarDayString: date.calendarDayString)
//            logger.debug("Inserting new DayEntity...")
//            context.insert(newDay)
//            dayEntity = newDay
//        }
//
//        logger.debug("Now that we have dayEntity, creating MealEntity")
//
//        let mealEntity = MealEntity(
//            dayEntity: dayEntity,
//            name: name,
//            time: time.timeIntervalSince1970
//        )
//        logger.debug("Inserting new MealEntity...")
//        context.insert(mealEntity)
//        logger.debug("Saving the context...")
//        try context.save()
//
//        logger.debug("Returning the newly created Meal")
//        return Meal(
//            mealEntity,
//            dayEntity: dayEntity,
//            foodItems: []
//        )
//    }
//    
//    func delete(_ meal: Meal) throws {
//        let id = meal.id
//        let descriptor = FetchDescriptor<MealEntity>(predicate: #Predicate {
//            $0.uuid == id
//        })
//        guard let meal = try context.fetch(descriptor).first else {
//            return
//        }
//        context.delete(meal)
//        try context.save()  
//    }
//
//    static func delete(_ meal: Meal) {
//        Task {
//            do {
//                try await shared.delete(meal)
//                await MainActor.run {
//                    post(.didDeleteMeal, userInfo: [.meal: meal])
//                }
//            } catch {
//                logger.error("Error deleting meal: \(error, privacy: .public)")
//            }
//        }
//    }
//    static func create(name: String, time: Date, date: Date) {
//        Task {
//            do {
//                logger.info("Creating meal: \(name) at: \(time) on: \(date)")
//                let meal = try await shared.create(
//                    name: name,
//                    time: time,
//                    date: date
//                )
//                await MainActor.run {
//                    post(.didAddMeal, userInfo: [.meal: meal])
//                }
//            } catch {
//                logger.error("Error creating meal: \(error, privacy: .public)")
//            }
//        }
//    }
//}
//
//func fetchMeals(on date: Date, context: ModelContext) -> [Meal] {
//    do {
//        let calendarDayString = date.calendarDayString
//        
//        let logger = Logger(subsystem: "fetchMeals", category: "")
//
//        let dayDesc = FetchDescriptor<DayEntity>(predicate: #Predicate {
//            $0.calendarDayString == calendarDayString
//        })
//        guard let dayEntity = try context.fetch(dayDesc).first else {
//            return []
//        }
//        
//        let dayID = dayEntity.uuid
//        let mealsDesc = FetchDescriptor<MealEntity>(predicate: #Predicate {
//            $0.dayID == dayID
//        }, sortBy: [SortDescriptor(\.time)])
//        let mealEntities = try context.fetch(mealsDesc)
//        logger.debug("Fetching \(mealEntities.count) mealEntities for day: \(calendarDayString, privacy: .public)")
//
//        var meals: [Meal] = []
//        for mealEntity in mealEntities {
//            let mealID = mealEntity.uuid
//            let foodItemsDesc = FetchDescriptor<FoodItemEntity>(predicate: #Predicate {
//                $0.mealID == mealID
//            })
//            logger.debug("Fetching FoodItems with mealID: \(mealID, privacy: .public)")
//
//            let foodItemEntities = try context.fetch(foodItemsDesc)
//            logger.debug("Fetched \(foodItemEntities.count) FoodItems")
//            var foodItems: [FoodItem] = []
//            for foodItemEntity in foodItemEntities {
//                let foodID = foodItemEntity.foodID
//                let foodDesc = FetchDescriptor<FoodEntity>(predicate: #Predicate {
//                    $0.uuid == foodID
//                })
//                guard let foodEntity = try context.fetch(foodDesc).first else {
//                    fatalError()
//                }
//                foodItems.append(FoodItem(foodItemEntity, foodEntity: foodEntity))
//            }
//            
//            let meal = Meal(
//                mealEntity,
//                dayEntity: dayEntity,
//                foodItems: foodItems
//            )
//            meals.append(meal)
//        }
//        return meals
//    } catch {
//        return []
//    }
//}
