import SwiftUI
import OSLog
import Observation

import SwiftSugar
import SwiftHaptics
import ViewSugar

struct DayView: View {

    let logger = Logger(subsystem: "DayView", category: "")
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @Namespace var namespace
    
    let date: Date
    @State var safeAreaInsets: EdgeInsets
    
    @State var showingMealForm: Bool = false

    @State var isRefreshing = false

    @State var isFetching = false
    @State var fetchTask: Task<Void, Error>? = nil

    @State var emojiWidth: CGFloat = 0

    @State var meals: [Meal] = []

    let model = Model()
    
    let didModifyMeal = NotificationCenter.default.publisher(for: .didModifyMeal)
    let didPopulate = NotificationCenter.default.publisher(for: .didPopulate)
    
    let safeAreaDidChange = NotificationCenter.default.publisher(for: .safeAreaDidChange)

    @Observable class Model {
        var foodItemBeingEdited: FoodItem? = nil
    }

    init(date: Date) {
        self.date = date
        _safeAreaInsets = State(initialValue: currentSafeAreaInsets)
    }

    var body: some View {
        content
            .onDisappear(perform: disappeared)
            .onAppear(perform: appeared)
            .onReceive(didModifyMeal, perform: didModifyMeal)
//            .onReceive(didDeleteMeal, perform: didDeleteMeal)
            .onReceive(didPopulate, perform: didPopulate)
            .onReceive(safeAreaDidChange, perform: safeAreaDidChange)
    }
    
    var content: some View {
        ZStack {
            if !isRefreshing, !isFetching {
                if meals.count > 0 {
                    list
//                        .transition(.move(edge: .top))
                } else {
                    emptyContent
                }
            } else {
                ProgressView()
            }
        }
    }

    func safeAreaDidChange(notification: Notification) {
        guard let insets = notification.userInfo?[Notification.PrepKeys.safeArea] as? EdgeInsets else {
            fatalError()
        }
        self.safeAreaInsets = insets
    }

    func didPopulate(notification: Notification) {
        fetchMeals()
    }
    
    func fetchMeals() {
        Task.detached(priority: .userInitiated) {
            let meals = await MealsStore.meals(on: date)
            self.meals = meals
        }
    }
    
    func didModifyMeal(notification: Notification) {
        DispatchQueue.main.async {
            guard
                let info = notification.userInfo,
                let day = info[Notification.PrepKeys.day] as? Day,
                day.date == date
            else { return }
            
            let newMeals = day.meals
            if newMeals.count > meals.count {
                SoundPlayer.play(.tweetbotSwoosh)
//            } else if newMeals.count < meals.count {
//                SoundPlayer.play(.letterpressDelete)
            }
            
            withAnimation(.snappy) {
                self.meals = day.meals
//                self.meals.append(meal)
            }
        }
    }

//    func didDeleteMeal(notification: Notification) {
//        DispatchQueue.main.async {
//            guard let meal = notification.userInfo?[Notification.PrepKeys.meal] as? Meal,
//                  meal.date == self.date
//            else { return }
//            
//            SoundPlayer.play(.letterpressDelete)
//            withAnimation {
//                self.meals.removeAll(where: { $0.id == meal.id })
//            }
//        }
//    }

    func appeared() {
        fetchMeals()
    }
    
    var list: some View {
        GeometryReader { proxy in
            List {
                ForEach(meals) { meal in
                    MealView(
                        meal: meal
//                        leadingPadding: $leadingPadding,
//                        trailingPadding: $trailingPadding
                    )
                }
                addMealCell
            }
            .listStyle(.grouped)
            .scrollIndicators(.hidden)
            .contentMargins(.trailing, trailingPadding, for: .scrollIndicators)
            .contentMargins(.bottom, contentMarginBottom(proxy))
            .contentMargins(.bottom, scrollIndicatorMarginBottom, for: .scrollIndicators)
        }
    }
    
    var trailingPadding: CGFloat {
        verticalSizeClass == .compact ? safeAreaInsets.trailing : 0
    }
    
    func contentMarginBottom(_ proxy: GeometryProxy) -> CGFloat {
        40 + proxy.safeAreaInsets.bottom
//        100
    }
    var scrollIndicatorMarginBottom: CGFloat {
        verticalSizeClass == .compact ? 5 : 20
    }
    
    var newMealButton: some View {
        Button {
            showMealForm()
        } label: {
            HStack {
                Text("New Meal")
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.2 : 0.15
                    ))
            )
            
            .hoverEffect(.highlight)
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showingMealForm) { newMealForm }
        .matchedGeometryEffect(id: "addMealButton", in: namespace)
    }
    
    var emptyContent: some View {
        var addButton: some View {
            var label: some View {
                var plusIcon: some View {
                    Image(systemName: "plus")
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundStyle(Color(.secondarySystemFill))
                        )
                }
                return HStack {
//                    plusIcon
                    Text("New Meal")
                        .fontWeight(.bold)
                }
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor.opacity(
                            colorScheme == .dark ? 0.2 : 0.15
                        ))
                )
            }
            
            var button: some View {
                Button {
                    showMealForm()
                } label: {
                    label
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showingMealForm) { newMealForm }
                .matchedGeometryEffect(id: "addMealButton", in: namespace)
            }
            
            return button
        }
        return VStack {
            Spacer()
            ContentUnavailableView(
                "No Meals",
                systemImage: "fork.knife",
                description: Text("You haven't added any meals yet.")
            )
            .fixedSize(horizontal: true, vertical: true)
            newMealButton
//            addButton
            Spacer()
        }
    }
    
    func disappeared() {
        /// Refresh the view so that scroll positions resets upon reuse.
        /// Do this here and no in `onAppear()` so that user doesn't
        /// see the removal and re-insertion of the list.
        refresh()
    }
    
    func refresh() {
        Task {
//            showingFoodPicker = false
            withAnimation(.snappy) {
                isRefreshing = true
            }
            try await sleepTask(0.1)
            withAnimation(.snappy) {
                isRefreshing = false
            }
        }
    }

    func showMealForm() {
        Haptics.selectionFeedback()
        showingMealForm = true
    }
    
    var addMealCell: some View {
        HStack {
            Spacer()
            newMealButton
            Spacer()
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(EmptyView())
        .listRowSeparator(.hidden)
    }

    var newMealForm: some View {
        MealForm(date)
    }
}
