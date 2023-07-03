import SwiftUI
import OSLog
import SwiftData
import Observation

import SwiftHaptics
import AlertLayer
import SwiftSugar

struct HomeView: View {
        
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @State var trailingSafeArea: CGFloat = 0
    @State var leadingSafeArea: CGFloat = 0

    @State var currentDate: Date? = nil
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                tabView
                alertLayer
            }
            .onChange(of: verticalSizeClass) { _, _ in
                setSafeAreaPadding(proxy)
            }
            .onAppear { appeared(proxy) }
        }
    }
    
    var tabView: some View {
        TabView {
            log
            nutrition
            goals
            foods
            settings
        }
    }

    func setSafeAreaPadding(_ proxy: GeometryProxy) {
        trailingSafeArea = proxy.safeAreaInsets.trailing
        leadingSafeArea = proxy.safeAreaInsets.leading
    }
    
    func appeared(_ proxy: GeometryProxy) {
//        let newItem = MealEntity(name: "", time: Date.now.timeIntervalSince1970)
//        context.insert(newItem)
//        try! context.save()

        if currentDate == nil {
            currentDate = Date.now.setting(year: 2023, month: 6, day: 18).startOfDay
//            currentDate = Date.now.startOfDay
        }
        setSafeAreaPadding(proxy)
    }
    
    var alertLayer: some View {
        EmptyView()
//        AlertLayer(
//            message: $alertMessage,
//            isPresented: $showingAlert
//        )
    }
    
    //MARK: - Detail Views

    var log: some View {
        LogView(
            currentDate: $currentDate,
            trailingSafeArea: $trailingSafeArea,
            leadingSafeArea: $leadingSafeArea
        )
        .tabItem {
            Label("Log", systemImage: "book.closed")
        }
    }

    var nutrition: some View {
        Text("Nutrition")
            .tabItem {
                Label("Nutrition", systemImage: "chart.bar.doc.horizontal")
            }
    }

    var goals: some View {
        Text("Goals")
            .tabItem {
                Label("Goals", systemImage: "target")
            }
    }
    
    var foods: some View {
        FoodsView()
            .tabItem {
                Label("My Foods", systemImage: "carrot")
            }
    }
    
    var settings: some View {
        Text("Settings")
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
    }
}
