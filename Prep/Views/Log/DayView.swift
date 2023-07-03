import SwiftUI
import OSLog
import SwiftData
import Observation

import SwiftSugar
import SwiftHaptics
import ViewSugar

struct DayView: View {

    let logger = Logger(subsystem: "DayView", category: "")
    
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @Namespace var namespace
    
    let date: Date
    
    @Binding var leadingPadding: CGFloat
    @Binding var trailingPadding: CGFloat
    
    @State var mealModel = MealModel()
    
    @State var showingMealForm: Bool = false

    @State var isRefreshing = false

    @State var isFetching = false
    @State var fetchTask: Task<Void, Error>? = nil

    @State var emojiWidth: CGFloat = 0

    @State var meals: [Meal]

    let model = Model()
    
    let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
    let didDeleteMeal = NotificationCenter.default.publisher(for: .didDeleteMeal)

    @Observable class Model {
        var foodItemBeingEdited: FoodItemEntity? = nil
    }

    init(
        date: Date,
        leadingPadding: Binding<CGFloat>,
        trailingPadding: Binding<CGFloat>
    ) {
        self.date = date
        _leadingPadding = leadingPadding
        _trailingPadding = trailingPadding
        
        _meals = State(initialValue: [])
    }
    
    var body: some View {
        content
            .onDisappear(perform: disappeared)
            .onAppear(perform: appeared)
            .onReceive(didAddMeal, perform: didAddMeal)
            .onReceive(didDeleteMeal, perform: didDeleteMeal)
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
    
    func didAddMeal(notification: Notification) {
        DispatchQueue.main.async {
            guard let meal = notification.userInfo?[Notification.PrepKeys.meal] as? Meal,
                  meal.date == self.date
            else { return }
            
            SoundPlayer.play(.tweetbotSwoosh)
            withAnimation {
                self.meals.append(meal)
            }
            
            /// Delaying slightly to try and avoid "The model configuration used to open the store is incompatible" error.
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                Task {
//                    logger.debug("didAddMeal: Saving context")
//                    try context.save()
//                }
//            }
        }
    }

    func didDeleteMeal(notification: Notification) {
        DispatchQueue.main.async {
            guard let meal = notification.userInfo?[Notification.PrepKeys.meal] as? Meal,
                  meal.date == self.date
            else { return }
            
            SoundPlayer.play(.letterpressDelete)
            withAnimation {
                self.meals.removeAll(where: { $0.id == meal.id })
            }
        }
    }

    func appeared() {
//        logger.debug("Fetching meals...")
//        let meals = fetchMeals(on: date, context: context)
//        self.meals = meals
//        logger.debug("... fetched \(meals.count) meals")
//        
//        Task.detached {
//            /// Doing this crashes if we then try to add a meal, getting the following error:
//            /// "The model configuration used to open the store is incompatible with the one that was used to create the store."
//            ///
////            let meals = try await FetchMealStore.shared.meals(date: date)
////            await MainActor.run {
////                self.meals = meals
////                logger.debug("... fetched \(meals.count) meals")
////            }
//        }
    }
    
    var list: some View {
        GeometryReader { proxy in
            List {
                ForEach(meals) { meal in
                    MealView(
                        meal: meal,
                        leadingPadding: $leadingPadding,
                        trailingPadding: $trailingPadding
                    )
                }
                addMealCell
            }
            .listStyle(.grouped)
            .contentMargins(.trailing, trailingPadding, for: .scrollIndicators)
            .contentMargins(.bottom, contentMarginBottom(proxy))
            .contentMargins(.bottom, scrollIndicatorMarginBottom, for: .scrollIndicators)
        }
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
        let date: Date = self.date.isToday ? Date.now : self.date.setting(hour: 12)
        mealModel.reset(date: date)
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
        MealForm(model: mealModel)
            .frame(minWidth: 200, idealWidth: 450, minHeight: 250, idealHeight: 340)
            .presentationDetents([.height(400)])
    }
}
