//
//  PrepApp.swift
//  Prep
//
//  Created by Ahmed Khalaf on 3/7/2023.
//

import SwiftUI

@main
struct PrepApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
