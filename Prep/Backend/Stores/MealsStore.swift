import Foundation
import CoreData
import OSLog

private let logger = Logger(subsystem: "MealsStore", category: "")

class MealsStore {
    static let shared = MealsStore()
    
    static func meals(on date: Date) async -> [Meal2] {
        await DataManager.shared.day(for: date)?.meals ?? []
    }
}

extension DataManager {
    func day(for date: Date) async -> Day2? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.dayEntity(for: date) { dayEntity in
                        guard let dayEntity else {
                            continuation.resume(returning: nil)
                            return
                        }
                        let day = Day2(dayEntity)
                        continuation.resume(returning: day)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error getting day for date: \(date.calendarDayString, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}

extension CoreDataManager {
    func dayEntity(for date: Date, completion: @escaping ((DayEntity2?) -> ())) throws {
        Task {
            let bgContext =  newBackgroundContext()
            await bgContext.perform {
                do {
                    let dayString = date.calendarDayString
                    let predicate = NSPredicate(format: "dateString == %@", dayString)

//                    let days = try DayEntity2.objects(for: predicate, in: bgContext)
                    
                    let request: NSFetchRequest<DayEntity2> = DayEntity2.fetchRequest()
                    request.predicate = predicate
//                    request.relationshipKeyPathsForPrefetching = ["mealEntities.foodItemEntities.foodEntity", "mealEntities.foodItemEntities.mealEntity"]
                    let days = try bgContext.fetch(request)

                    logger.info("Fetched day for: \(dayString, privacy: .public)")
                    completion(days.first)
                } catch {
                    logger.error("Error: \(error.localizedDescription, privacy: .public)")
                    completion(nil)
                }
            }
        }
    }
}
