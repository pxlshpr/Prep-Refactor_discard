//import Foundation
//import SwiftData
//import OSLog
//import SwiftSugar
//
//actor Database: ModelActor {
//    
//    static let shared = Database()
//    
//    let logger = Logger(subsystem: "Database", category: "")
//    let executor: any ModelExecutor
//    init() {
//        let container = try! ModelContainer(for: allModelTypes)
//        let context = ModelContext(container)
//        let executor = DefaultModelExecutor(context: context)
//        self.executor = executor
//    }
//    
//    func meal(_ uuid: String) -> MealEntity? {
//        do {
//            let descriptor = FetchDescriptor<MealEntity>(predicate: #Predicate { $0.uuid == uuid })
//            let meal = try context.fetch(descriptor).first
//            return meal
//        } catch {
//            return nil
//        }
//    }
//    
//    func food(_ uuid: String) -> FoodEntity? {
//        do {
//            let descriptor = FetchDescriptor<FoodEntity>(predicate: #Predicate { $0.uuid == uuid })
//            let meal = try context.fetch(descriptor).first
//            return meal
//        } catch {
//            return nil
//        }
//    }
//
//    func day(for date: Date) -> DayEntity? {
//        do {
//            let calendarDayString = date.calendarDayString
//            let descriptor = FetchDescriptor(predicate: #Predicate<DayEntity> {
//                $0.calendarDayString == calendarDayString
//            })
//            let days = try context.fetch(descriptor)
//            guard days.count <= 1 else {
//                fatalError("Duplicate days for: \(date.calendarDayString)")
//            }
//            return days.first
//        } catch {
//            logger.error("Error fetching DayEntity: \(error)")
//            return nil
//        }
//    }
//    
//    func createDay(date: Date) throws -> DayEntity {
//        let day = DayEntity(calendarDayString: date.calendarDayString)
//        context.insert(day)
//        try context.save()
//        return day
//    }
//    
//    func fetchOrCreateDay(for date: Date) throws -> DayEntity {
//        guard let day = day(for: date) else {
//            return try createDay(date: date)
//        }
//        return day
//    }
//    
//    func delete(_ meal: MealEntity) {
//        do {
//            let meal = context.object(with: meal.objectID)
//            context.delete(meal)
//            try context.save()
//        } catch {
//            logger.error("Error deleting MealEntity: \(error)")
//        }
//    }
//
//    func delete(_ food: FoodEntity) {
//        do {
//            let food = context.object(with: food.objectID)
//            context.delete(food)
//            try context.save()
//        } catch {
//            logger.error("Error deleting FoodEntity: \(error)")
//        }
//    }
//
//    func createMeal(name: String, time: Date, date: Date) {
//        do {
//            let day = try fetchOrCreateDay(for: date)
//            let meal = MealEntity(
//                dayEntity: day,
//                name: name,
//                time: time.timeIntervalSince1970
//            )
//            context.insert(meal)
//            try context.save()
//        } catch {
//            logger.error("Error creating MealEntity: \(error)")
//        }
//    }
//}
