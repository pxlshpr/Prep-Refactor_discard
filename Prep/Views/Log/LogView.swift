import SwiftUI
import OSLog

import SwiftHaptics
import SwiftSugar

struct LogView: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @Binding var currentDate: Date?
    @State var calendarPosition: String? = nil

    @State var showingFoodPicker: Bool = false
    @State var showingFoodForm: Bool = false
    @State var showingMealForm: Bool = false

    @State var meals: [Meal] = []

    @State var mealToShowFoodPickerFor: Meal? = nil
    
    @State var foodModel = FoodModel()
    
    let didPopulate = NotificationCenter.default.publisher(for: .didPopulate)
    let didModifyMeal = NotificationCenter.default.publisher(for: .didModifyMeal)

    var body: some View {
        GeometryReader { proxy in
//            HStack(spacing: 0) {
//                if horizontalSizeClass == .regular {
//                    calendarView(proxy)
//                }
                ZStack {
                    scrollView(proxy)
                    LogNavigationBar(
                        currentDate: $currentDate,
                        proxy: proxy
                    )
                    buttonsLayer
                }
//            }
        }
        .onAppear(perform: appeared)
        .onReceive(didPopulate, perform: didPopulate)
        .onReceive(didModifyMeal, perform: didModifyMeal)
        .onChange(of: currentDate, currentDateChanged)
    }
    
    func appeared() {
        fetchMeals()
    }
    
    func didPopulate(notification: Notification) {
        fetchMeals()
    }
    func didModifyMeal(notification: Notification) {
        fetchMeals()
    }

    func currentDateChanged(oldValue: Date?, newValue: Date?) {
        fetchMeals(newValue)
    }
    
    func fetchMeals(_ date: Date? = nil) {
        guard let date = date ?? currentDate else {
            meals = []
            return
        }
        Task.detached(priority: .userInitiated) {
            let meals = await MealsStore.meals(on: date)
            self.meals = meals
        }
    }
    
    func calendarView(_ proxy: GeometryProxy) -> some View {
        CalendarView(
            currentDate: $currentDate,
            calendarPosition: $calendarPosition,
            proxy: proxy
        )
    }
    
    var newFoodForm: some View {
        FoodForm(model: foodModel)
    }
    
    var foodPicker: some View {
        FoodPicker { _ in
            showingFoodPicker = false
        }
    }
    
    func scrollView(_ proxy: GeometryProxy) -> some View {
        HStack(spacing: 0) {
//            if horizontalSizeClass == .regular {
//                CalendarView(
//                    currentDate: $currentDate,
//                    calendarPosition: $calendarPosition,
//                    proxy: proxy
//                )
//            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(dates, id: \.self) { date in
                        dayView(date, proxy)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentDate)
            .ignoresSafeArea(edges: .all)
        }
    }
    
    var metricsHeight: CGFloat {
        verticalSizeClass == .regular ? MetricsHeight : MetricsHeightCompact
    }

    func dayView(_ date: Date, _ proxy: GeometryProxy) -> some View {
        var topInset: some View {
            Spacer().frame(height: barHeight(proxy) + metricsHeight)
        }
        
        var bottomInset: some View {
            Spacer().frame(height: HeroButton.bottom + HeroButton.size)
        }
        
        return DayView(date: date)
            .safeAreaInset(edge: .top) { topInset}
            .safeAreaInset(edge: .bottom) { bottomInset }
    }

    @ViewBuilder
    var todayButton: some View {
        if currentDate?.startOfDay != Date.now.startOfDay {
            Button {
                Haptics.selectionFeedback()
                SoundPlayer.play(.clearSwoosh)
                post(.didTapToday)
                withAnimation {
                    currentDate = Date.now.startOfDay
                }
            } label: {
                Text("Today")
                    .font(.system(.subheadline, weight: .medium))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .hoverEffect(.highlight)
            }
            .padding(.trailing, 5)
        }
    }
    
    var buttonsLayer: some View {

        var button: some View {
            var menu: some View {
                
                return Menu {
                    Menu {
                        Button {
                            showingMealForm = true
                        } label: {
                            Label("Meal", systemImage: "note.text")
                        }
                        Divider()
                        Section {
                            ForEach(FoodType.allCases) { foodType in
                                Button {
                                    Haptics.selectionFeedback()
                                    foodModel.reset(newFoodType: foodType)
                                    showingFoodForm = true
                                } label: {
                                    Label(foodType.name, systemImage: foodType.systemImage)
                                }
                            }
                        }
                    } label: {
                        Text("New")
                    }
                    Section("Add Food") {
                        ForEach(meals.sorted().reversed()) { meal in
                            Button(meal.title) {
                                mealToShowFoodPickerFor = meal
                            }
                        }
                    }
                } label: {
                    label
                }
            }
            
            var label: some View { heroButtonLabel("plus") }
            
            return ZStack {
                label
                menu
            }
        }
        
        func foodPicker(for meal: Meal) -> some View {
//            let binding = Binding<Bool>(
//                get: { mealToShowFoodPickerFor != nil },
//                set: { newValue in
//                    if !newValue {
//                        mealToShowFoodPickerFor = nil
//                    }
//                }
//            )
//            return FoodPicker(isPresented: binding, meal: meal)
            return FoodPicker { _ in
                mealToShowFoodPickerFor = nil
            }
        }

        var addFoodButton: some View {
//            buttonLegacy
            button
//                .popover(isPresented: $showingFoodPicker) { foodPicker }
                .popover(item: $mealToShowFoodPickerFor) { foodPicker(for: $0) }
                .popover(isPresented: $showingMealForm) { mealForm }
        }
        
        @ViewBuilder
        var mealForm: some View {
            if let currentDate {
                MealForm(currentDate)
            }
        }
        
        return VStack {
            Spacer()
            HStack(alignment: .bottom) {
                Spacer()
                addFoodButton
                    .popover(isPresented: $showingFoodForm) { newFoodForm }
                    .hoverEffect(.lift)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, HeroButton.bottom)
        }
        .ignoresSafeArea(.keyboard)
    }
    
    var title: String {
        let date = currentDate ?? Date.now.startOfDay
        return date.logDateString()
//        return date.logDateString(longDayNames: horizontalSizeClass == .regular)
    }

    func titleLayer(_ proxy: GeometryProxy) -> some View {
        
        var offsetY: CGFloat {
            proxy.safeAreaInsets.top / 2.0
        }
        
        var dateMenu: some View {
            var buttonWidth: CGFloat { 20 }
            return Button {
                Haptics.selectionFeedback()
            } label: {
                HStack {
                    Text(title)
                        .minimumScaleFactor(0.7)
                        .font(.title2)
                        .foregroundStyle(Color(.label))
                        .bold()
                    Image(systemName: "chevron.down.circle.fill")
                        .symbolRenderingMode(.palette)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(.secondaryLabel), Color(.secondarySystemFill))
                        .imageScale(.medium)
                        .frame(width: buttonWidth)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .offset(x: buttonWidth/2.0)
                .hoverEffect(.highlight)
            }
        }
        
        var dateButtonLayer: some View {
            HStack(spacing: 0) {
                Spacer()
                dateMenu
                Spacer()
            }
        }
        
        var todayButtonLayer: some View {
            HStack {
                Spacer()
                todayButton
            }
            .padding(.trailing, proxy.safeAreaInsets.trailing + 5)
        }
        
        var titleBar: some View {
            ZStack {
                dateButtonLayer
                todayButtonLayer
            }
            .offset(y: offsetY)
            .frame(height: barHeight(proxy))
            .background(.bar)
        }
        
        return VStack(spacing: 0) {
            titleBar
            Spacer()
        }
        .ignoresSafeArea(edges: .all)
    }
    
    func barHeight(_ proxy: GeometryProxy) -> CGFloat {
        44 + proxy.safeAreaInsets.top
    }

    var dates: [Date] {
        let dayDurationInSeconds: TimeInterval = 60*60*24
        let start = Date.now.startOfDay.moveDayBy(-365)
        let end = Date.now.startOfDay.moveDayBy(365)
        return Array(stride(from: start, to: end, by: dayDurationInSeconds))
    }
}

struct HeroButton {
    static let bottom: CGFloat = 10
    static let size: CGFloat = 48
}
