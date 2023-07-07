import SwiftUI

@main
struct PrepApp: App {
    
    init() {
        DataManager.populateIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
