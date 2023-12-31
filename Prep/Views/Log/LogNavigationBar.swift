import SwiftUI

import SwiftHaptics
import FoodDataTypes

let DummyEnergyUpper: Double = 1800
let DummyEnergyLower: Double = 1300
let DummyCarbUpper: Double = 30
let DummyCarbLower: Double = 5
let DummyFatUpper: Double = 150
let DummyFatLower: Double = 50
let DummyProteinUpper: Double = 250
let DummyProteinLower: Double = 80

struct LogNavigationBar: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @State var day: Day = Day()
    @Binding var currentDate: Date?
    var proxy: GeometryProxy
    
    let didAddFoodItem = NotificationCenter.default.publisher(for: .didAddFoodItem)
    let didDeleteFoodItem = NotificationCenter.default.publisher(for: .didDeleteFoodItem)
    let didPopulate = NotificationCenter.default.publisher(for: .didPopulate)
    let didModifyMeal = NotificationCenter.default.publisher(for: .didModifyMeal)

    init(
        currentDate: Binding<Date?>,
        proxy: GeometryProxy
    ) {
        _currentDate = currentDate
        self.proxy = proxy
    }
    
    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Spacer()
        }
        .ignoresSafeArea(edges: .all)
        .onAppear(perform: appeared)
        .onChange(of: currentDate, currentDateChanged)
        .onReceive(didAddFoodItem, perform: didUpdateDay)
        .onReceive(didDeleteFoodItem, perform: didUpdateDay)
        .onReceive(didModifyMeal, perform: didUpdateDay)
        .onReceive(didPopulate, perform: didPopulate)
    }
    
    func didUpdateDay(notification: Notification) {
        guard let day = notification.userInfo?[Notification.PrepKeys.day] as? Day,
              day.dateString == self.day.dateString
        else {
            return
        }
        
        /// Wait a bit for the form to dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.smooth) {
                self.day = day
            }
        }
    }
    
    func didPopulate(notification: Notification) {
        fetchDay()
    }
    
    func currentDateChanged(oldValue: Date?, newValue: Date?) {
        fetchDay()
    }
    
    func appeared() {
        fetchDay()
    }
    
    func fetchDay() {
        guard let currentDate else {
            self.day = Day()
            return
        }
        Task.detached(priority: .high) {
            let day = await DaysStore.day(for: currentDate)
            await MainActor.run {
                withAnimation(.smooth) {
                    self.day = day ?? Day()
                }
            }
        }
    }
    
    var titleBar: some View {
        ZStack {
            Group {
                dateButtonLayer
                todayButtonLayer
            }
            .offset(y: offsetY)
            metricsViewLayer
        }
        .frame(height: barHeight)
        .background(.regularMaterial)
    }
    
    var dateButtonLayer: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                dateMenu
                Spacer()
            }
            Color.clear
                .frame(height: metricsHeight)
        }
    }
    
    var metricsViewLayer: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            metricsView
        }
    }

    
    var todayButtonLayer: some View {
        @ViewBuilder
        var todayButton: some View {
            if currentDate?.startOfDay != Date.now.startOfDay {
                Button {
                    Haptics.selectionFeedback()
                    SoundPlayer.play(.clearSwoosh)
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
        
        return VStack(spacing: 0) {
            HStack {
                Spacer()
                todayButton
            }
            .padding(.trailing, proxy.safeAreaInsets.trailing + 5)
            Color.clear
                .frame(height: metricsHeight)
        }
    }
    
    var dateMenu: some View {
        var buttonWidth: CGFloat { 20 }
        
        var title: String {
            let date = currentDate ?? Date.now.startOfDay
            return date.logDateString()
            //            return date.logDateString(longDayNames: horizontalSizeClass == .regular)
        }
        
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
}

extension LogNavigationBar {
    
    @ViewBuilder
    var metricsView: some View {
        if verticalSizeClass == .regular {
            energyAndMacrosPage
        }
    }
    
    var energyAndMacrosPage: some View {
        Group {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
//                    backgroundColor
                    VStack(spacing: 10) {
                        energyRow(proxy)
                        macros(proxy)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: metricsHeight)
        .padding(.trailing, proxy.safeAreaInsets.trailing)
        .padding(.leading, proxy.safeAreaInsets.leading)
    }
    
    var metricsHeight: CGFloat {
        verticalSizeClass == .regular ? MetricsHeight : MetricsHeightCompact
    }

    var backgroundColor: Color {
        colorScheme == .light ? Color(.systemGroupedBackground) : Color(hex: "191919")
    }
    
    func energyRow(_ proxy: GeometryProxy) -> some View {
        
        var energyView: some View {
            var badge: some View {
                FoodBadge(
                    c: day.carb,
                    f: day.fat,
                    p: day.protein,
                    width: .constant(proxy.size.width)
                )
                .frame(height: 12)
            }
            
            var meter: some View {
                NutrientMeter(model: .init(get: {
                    .init(
                        component: .energy(unit: .kcal),
                        goalLower: energyLower,
                        goalUpper: energyUpper,
                        planned: day.energy,
                        eaten: 0
                    )
                }, set: { _ in }))
                .frame(height: 12)
            }
            
            return Group {
//                if data.haveEnergyGoal {
                    meter
//                } else {
//                    badge
//                }
            }
        }
        
        return VStack(spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Color.clear
                    .animatedEnergyValue(value: day.energy)
                Spacer()
                Color.clear
                    .animatedEnergyRemainingValue(value: energyRemaining)
            }
            .padding(.horizontal, 10)
            energyView
        }
    }
    
    var energyUpper: Double { DummyEnergyUpper }
    var energyLower: Double { DummyEnergyLower }
    var carbUpper: Double { DummyCarbUpper }
    var carbLower: Double { DummyCarbLower }
    var fatUpper: Double { DummyFatUpper }
    var fatLower: Double { DummyFatLower }
    var proteinUpper: Double { DummyProteinUpper }
    var proteinLower: Double { DummyProteinLower }

    var energyRemaining: Double {
        energyUpper - day.energy
    }
    
    func macros(_ proxy: GeometryProxy) -> some View {
        let spacing: CGFloat = 5.0
        
        var macroWidth: CGFloat {
            let width = (proxy.size.width / 3.0) - (3 * 1.0)
            return max(width, 0)
        }
        
        var backgroundColor: Color {
            colorScheme == .light ? .white : Color(hex: "232323")
            //            Color(.tertiarySystemBackground)
        }
        
        func macroView(for macro: Macro) -> some View {
            
            var goalLower: Double? {
                switch macro {
                case .carb:
                    return carbLower
                case .fat:
                    return fatLower
                case .protein:
                    return proteinLower
                }
            }
            
            var goalUpper: Double? {
                switch macro {
                case .carb:
                    return carbUpper
                case .fat:
                    return fatUpper
                case .protein:
                    return proteinUpper
                }
            }
            
            var value: Double {
                switch macro {
                case .carb:
                    return day.carb
                case .fat:
                    return day.fat
                case .protein:
                    return day.protein
                }
            }

            var meterView: some View {
                NutrientMeter(model: .init(get: {
                    .init(
                        component: macro.nutrientMeterComponent,
                        goalLower: goalLower,
                        goalUpper: goalUpper,
                        planned: value,
                        eaten: 0
                    )
                }, set: { _ in }))
                .frame(height: 7)
                .padding(.top, 5)
                .padding(.bottom, 1)
            }
            
            var meterOpacity: CGFloat {
//                day.haveGoal(for: macro) ? 1 : 0
                1
            }
            
            return VStack(spacing: 0) {
                HStack {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(macro.fillColor(for: colorScheme).gradient)
                        .frame(width: 10, height: 10)
                    Text(macro.abbreviatedDescription)
                        .font(.system(.footnote, design: .rounded, weight: .regular))
                        .foregroundStyle(Color(.secondaryLabel))
                    Spacer()
                }
                meterView
                    .opacity(meterOpacity)
                HStack {
                    Spacer()
                    Color.clear
                        .animatedMacroValue(value: day.value(for: macro))
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .frame(width: macroWidth)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(backgroundColor)
            )
        }
        
        return HStack(spacing: spacing) {
            ForEach(Macro.allCases, id: \.self) { macro in
                macroView(for: macro)
            }
        }
    }
}

extension LogNavigationBar {
    
    var offsetY: CGFloat {
        proxy.safeAreaInsets.top / 2.0
    }

    var barHeight: CGFloat {
        44 + proxy.safeAreaInsets.top + metricsHeight
    }
}

let MetricsHeight: CGFloat = 140
let MetricsHeightCompact: CGFloat = 0
