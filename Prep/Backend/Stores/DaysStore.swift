import Foundation
import CoreData
import OSLog

private let logger = Logger(subsystem: "DayStore", category: "")

class DaysStore {
    static let shared = DaysStore()
    
    static func day(for date: Date) async -> Day? {
        await DataManager.shared.day(for: date)
    }
}

extension DataManager {
    func day(for date: Date) async -> Day? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.dayEntity(for: date) { dayEntity in
                        guard let dayEntity else {
                            continuation.resume(returning: nil)
                            return
                        }
                        let day = Day(dayEntity)
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
    func dayEntity(for date: Date, completion: @escaping ((DayEntity?) -> ())) throws {
        Task {
            let bgContext =  newBackgroundContext()
            await bgContext.perform {
                do {
                    let dayString = date.calendarDayString
                    let predicate = NSPredicate(format: "dateString == %@", dayString)

//                    let days = try DayEntity.objects(for: predicate, in: bgContext)
                    
                    let request: NSFetchRequest<DayEntity> = DayEntity.fetchRequest()
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