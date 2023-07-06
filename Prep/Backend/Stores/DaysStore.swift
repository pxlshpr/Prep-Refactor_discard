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
    
    func fetchOrCreateDay(for date: Date, in context: NSManagedObjectContext) -> DayEntity {
        dayEntity(for: date, in: context)
        ?? createDayEntity(for: date, in: context)
    }
    
    func createDayEntity(for date: Date, in context: NSManagedObjectContext) -> DayEntity {
        let entity = DayEntity()
        entity.dateString = date.calendarDayString
        context.insert(entity)
        return entity
    }
    
    func dayEntity(for date: Date, in context: NSManagedObjectContext) -> DayEntity? {
        DayEntity.objects(
            for: NSPredicate(format: "dateString == %@", date.calendarDayString),
            fetchLimit: 1,
            in: context
        ).first
    }
    
    func dayEntity(for date: Date, completion: @escaping ((DayEntity?) -> ())) throws {
        Task {
            let bgContext =  newBackgroundContext()
            await bgContext.perform {
                let day = self.dayEntity(for: date, in: bgContext)
                completion(day)
            }
        }
    }
}
