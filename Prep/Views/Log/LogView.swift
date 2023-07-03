import SwiftUI
import OSLog

import SwiftHaptics
import SwiftSugar

struct LogView: View {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @Binding var currentDate: Date?
    @Binding var trailingSafeArea: CGFloat
    @Binding var leadingSafeArea: CGFloat

    @State var showingFoodPicker: Bool = false
    @State var showingFoodForm: Bool = false
    @State var showingMealForm: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                scrollView(proxy)
                titleLayer(proxy)
                buttonsLayer
            }
//            .sheet(isPresented: $showingFoodPicker) { foodPicker }
        }
    }
    
    var foodForm: some View {
        FoodForm()
    }
    
    var foodPicker: some View {
        FoodPicker(isPresented: $showingFoodPicker)
    }
    
    func scrollView(_ proxy: GeometryProxy) -> some View {
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
    
    func dayView(_ date: Date, _ proxy: GeometryProxy) -> some View {
        DayView(
            date: date,
//            showingMealForm: $showingMealForm,
            leadingPadding: leadingPaddingBinding,
            trailingPadding: $trailingSafeArea
        )
        .safeAreaInset(edge: .top) {
            Spacer().frame(height: barHeight(proxy))
        }
        .safeAreaInset(edge: .bottom) {
            Spacer().frame(height: HeroButton.bottom + HeroButton.size)
        }
    }

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
    
    var buttonsLayer: some View {
        
        func button(_ systemImage: String, action: @escaping () -> ()) -> some View {
             var label: some View {
                 ZStack {
                     Circle()
                         .foregroundStyle(Color.accentColor.gradient)
                         .shadow(color: Color(.black).opacity(0.1), radius: 5, x: 0, y: 3)
                     Image(systemName: systemImage)
                         .font(.system(size: 25))
                         .fontWeight(.medium)
                         .foregroundStyle(Color(.systemBackground))
                 }
                 .frame(width: HeroButton.size, height: HeroButton.size)
                 .hoverEffect(.lift)
            }
             
            var menu: some View {
                Menu {
                    Button {
                        showingFoodForm = true
                    } label: {
                        Label("New Food", systemImage: "plus")
                    }
                } label: {
                    label
                } primaryAction: {
                    action()
                }
            }
             
             return ZStack {
                 label
                 menu
             }
        }
        
        var addFoodButton: some View {
            button("carrot.fill") {
                Haptics.selectionFeedback()
                showingFoodPicker = true
            }
            .popover(isPresented: $showingFoodPicker) { foodPicker }
        }
        
        return VStack {
            Spacer()
            HStack(alignment: .bottom) {
                Spacer()
                addFoodButton
                    .popover(isPresented: $showingFoodForm) { foodForm }
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
    
    var includeHorizontalPadding: Bool {
        verticalSizeClass == .compact
    }
    
    var leadingPadding: CGFloat {
        includeHorizontalPadding ? leadingSafeArea : 0
    }

    var trailingPadding: CGFloat {
        includeHorizontalPadding ? trailingSafeArea : 0
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
    
    var leadingPaddingBinding: Binding<CGFloat> {
        Binding<CGFloat>(
            get: { leadingPadding },
            set: { _ in }
        )
    }
}

struct HeroButton {
    static let bottom: CGFloat = 10
    static let size: CGFloat = 48
}
