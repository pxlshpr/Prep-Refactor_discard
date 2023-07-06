import SwiftSugar
import OSLog

extension ItemForm {
    func delayedSetSaveDisabled() {
        saveDisabledTask?.cancel()
        saveDisabledTask = Task.detached(priority: .userInitiated) {
            /// sleep to let the animation complete first
            try await sleepTask(0.2)
            try Task.checkCancellation()
            await MainActor.run {
                self.setSaveDisabled()
            }
        }
    }

    func setSaveDisabled() {
        guard !isDeleting else {
            saveDisabled = true
            dismissDisabled = true
            return
        }
        saveDisabled = shouldDisableSave
        dismissDisabled = shouldDisableDismiss
    }
    
    func hasPendingChanges(from foodItem: FoodItem) -> Bool {
        foodValue != foodItem.amount
    }
    
    var isValid: Bool {
        guard let amountDouble, amountDouble > 0 else {
            return false
        }
        return true
    }
    
    var shouldDisableSave: Bool {
        if let foodItem {
            /// Can be saved if we have pending changes
            !hasPendingChanges(from: foodItem)
        } else {
            !isValid
        }
    }
    
    var shouldDisableDismiss: Bool {
        if let foodItem {
            /// Can be saved if we have pending changes
            hasPendingChanges(from: foodItem)
        } else {
            hasEnteredData
        }
    }
    
    var hasEnteredData: Bool {
        foodValue != initialFoodValue
    }
}
