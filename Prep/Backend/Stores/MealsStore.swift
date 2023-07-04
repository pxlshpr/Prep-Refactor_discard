import Foundation
import CoreData
import OSLog

private let logger = Logger(subsystem: "MealsStore", category: "")

class MealsStore {
    static let shared = MealsStore()
    
    static func meals(on date: Date) async -> [Meal] {
        await DataManager.shared.day(for: date)?.meals ?? []
    }
}
