import SwiftUI

let FoodPageSize: Int = 25

@Observable class FoodsModel {
    
    static let shared = FoodsModel()
    
    var foods: [Food] = []
    var isLoadingPage = false
    var currentPage = 1
    var canLoadMorePages = true
    
    init() {
        loadMoreContent()
    }
    
    func loadMoreContentIfNeeded(currentFood food: Food? = nil) {
        guard let food else {
            loadMoreContent()
            return
        }
        
        let thresholdIndex = foods.index(foods.endIndex, offsetBy: -5)
        if foods.firstIndex(where: { $0.id == food.id }) == thresholdIndex {
            loadMoreContent()
        }
    }
    
    private func loadMoreContent() {
        guard !isLoadingPage && canLoadMorePages else { return }
        
        isLoadingPage = true
        
        Task.detached(priority: .userInitiated) {
            let foods = await FoodsStore.userFoods(page: self.currentPage)
            
            await MainActor.run {
                self.canLoadMorePages = foods.count == FoodPageSize
                self.isLoadingPage = false
                self.currentPage += 1
                self.foods.append(contentsOf: foods)
            }
        }
    }
}
