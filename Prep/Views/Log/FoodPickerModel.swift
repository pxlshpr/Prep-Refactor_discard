import SwiftUI
//import SwiftData
import OSLog
import SwiftSugar

@Observable class FoodPickerModel {
    
    let logger = Logger(subsystem: "FoodPickerModel", category: "")
    static let shared = FoodPickerModel()
    
    var foodResults: [Food] = []
    var task: Task<Void, Error>? = nil
    
    init() {
        fetchRecents()
        addObservers()
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didDeleteFoodItem), name: .didDeleteFoodItem, object: nil)
    }
    
    @objc func didDeleteFoodItem(_ notification: Notification) {
        /// Fetch recents again as last used info for foods might have changed
        fetchRecents()
    }
    
    func fetchRecents() {
        task?.cancel()
        task = Task {
            let recents = await SearchStore.recents()
            try Task.checkCancellation()
            logger.debug("Setting \(recents.count) recents")
            await MainActor.run {
                self.foodResults = recents
            }
        }
    }
    
    func reset() {
        fetchRecents()
    }
    
    func search(_ text: String) {
        task?.cancel()
        task = Task {
            let results = await SearchStore.search(text)
            try Task.checkCancellation()
            logger.debug("Setting \(results.count) results")
            await MainActor.run {
                self.foodResults = results
            }
        }
    }
}
