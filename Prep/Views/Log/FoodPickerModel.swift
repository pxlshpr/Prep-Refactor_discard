import SwiftUI
import SwiftData
import OSLog
import SwiftSugar

@Observable class FoodPickerModel {
    
    let logger = Logger(subsystem: "FoodPickerModel", category: "")
    static let shared = FoodPickerModel()
    
    var foodResults: [FoodResult] = []
    var task: Task<Void, Error>? = nil
    
    init() {
        fetchRecents()
    }
    
    func fetchRecents() {
        task?.cancel()
        task = Task {
//            do {
//                let recents = try await SearchStore.shared.recents()
//                try Task.checkCancellation()
//                logger.debug("Setting \(recents.count) recents")
//                await MainActor.run {
//                    self.foodResults = recents
//                }
//                
//            } catch {
//                logger.debug("Error during recents fetch: \(error, privacy: .public)")
//            }
        }
    }
    
    func reset() {
        fetchRecents()
    }
    
    func search(_ text: String) {
        task?.cancel()
        task = Task {
//            do {
//                let results = try await SearchStore.shared.search(text)
//                try Task.checkCancellation()
//                logger.debug("Setting \(results.count) results")
//                await MainActor.run {
//                    self.foodResults = results
//                }
//                
//            } catch {
//                logger.debug("Error during search: \(error, privacy: .public)")
//            }
        }
    }
}
