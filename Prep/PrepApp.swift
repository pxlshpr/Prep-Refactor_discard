import SwiftUI

@main
struct PrepApp: App {
    
//    let persistenceController = PersistenceController.shared
    
    @State var foodModel = FoodModel.shared
    
    init() {
        DataManager.populateIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
//            EmptyView()
            HomeView()
//                .environment(foodModel)
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
