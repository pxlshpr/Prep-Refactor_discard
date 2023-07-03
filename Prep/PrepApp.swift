import SwiftUI

@main
struct PrepApp: App {
    
//    let persistenceController = PersistenceController.shared
    
    init() {
        DataManager.populateIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
//            EmptyView()
            HomeView()
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
