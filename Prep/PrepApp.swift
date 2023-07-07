import SwiftUI

@main
struct PrepApp: App {
    
    @State var foodModel = FoodModel.shared
    
    init() {
        DataManager.populateIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
