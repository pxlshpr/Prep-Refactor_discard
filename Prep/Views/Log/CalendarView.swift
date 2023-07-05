import SwiftUI

/// Todos
/// [ ] Handle tap
/// [ ] Present this on phones, dismissing when there upon tapping
/// [ ] Initial scroll offset set so that current week is in middle. Use an id that we can construct

struct CalendarView: View {
    
    @Binding var currentDate: Date?
    @Binding var calendarPosition: String?
//    let proxy: GeometryProxy

    var firstWeekday: Int { 2 }
    
    var body: some View {
        ZStack {
            content
            headerLayer
        }
    }
    
    var headerLayer: some View {
        var string: String {
            guard let calendarPosition,
                  let year = calendarPosition.components(separatedBy: "_").first
            else { return "" }
            return year
        }
        return VStack {
            Text(string)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .frame(height: 70, alignment: .bottom)
                .frame(width: (dayWidth * 7) + 20 + 20, alignment: .leading)
                .padding(.bottom, 20)
                .padding(.leading, 20)
                .background(.regularMaterial)
            Spacer()
        }
    }
    
    var content: some View {
        HStack(spacing: 0) {
            scrollView
            separator
        }
    }
    
    var separator: some View {
        Rectangle()
            .foregroundStyle(Color(.secondaryLabel))
            .frame(width: 0.5)
    }
    
    var scrollView: some View {
        ScrollView(showsIndicators: false) {
            topInset
            LazyVStack {
                ForEach(years, id: \.self) { year in
                    yearView(year)
                }
            }
            .frame(width: dayWidth * 7)
        }
        .contentMargins(.horizontal, EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20), for: .scrollContent)
        .scrollPosition(id: $calendarPosition)
        .scrollTargetBehavior(.viewAligned)
        .onAppear {
            calendarPosition = "2023_5"
        }
    }
    
    var years: [Int] {
        [2021, 2022, 2023, 2024]
    }
    
    func yearView(_ year: Int) -> some View {
        LazyVStack(spacing: 0) {
            Text(String(year))
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            Divider()
                .padding(.vertical, 15)
                .padding(.horizontal, 10)
            ForEach(1...12, id: \.self) { month in
                monthView(month, year)
                    .id("\(year)_\(month)")
            }
        }
    }
    
    func monthView(_ month: Int, _ year: Int) -> some View {
        LazyVStack(spacing: 0) {
            Text("\(monthName(month))")
                .font(.title3)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
                .padding(.leading, 15)
            daysHeader
            ForEach(1...weeksInMonth(month, year), id: \.self) { week in
                weekView(week, month, year)
            }
        }
        .padding(.bottom, 10)
        .scrollTargetLayout()
    }
    
    func weekView(_ weekOfMonth: Int, _ month: Int, _ year: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                dayView(index: index, weekOfMonth: weekOfMonth, month: month, year: year)
            }
        }
        .id(weekID(year: year, month: month, weekOfMonth: weekOfMonth))
    }
    
    func weekID(year: Int, month: Int, weekOfMonth: Int) -> String {
        let string = "\(year)_\(month)_\(weekOfMonth)"
        print("ID for year: \(year), month: \(month), weekOfMonth: \(weekOfMonth) – \(string)")
        return string
    }
    
    func dayView(index: Int, weekOfMonth: Int, month: Int, year: Int) -> some View {
        var date: Date? {
            Date.day(index: index, weekOfMonth: weekOfMonth, month: month, year: year, firstWeekday: firstWeekday)
        }
        
        var string: String {
            guard let date else { return "" }
            return "\(date.day)"
        }
        
        return Text(string)
            .frame(width: dayWidth)
            .padding(.vertical, 5)
            .hoverEffect(.highlight)
    }
    
    var daysHeader: some View {
        func letter(at index: Int) -> String {
            var days = ["S", "M", "Tu", "W", "Th", "F", "Sa"]
            days.shiftRightInPlace(firstWeekday - 1) /// -1 since weekdays start at 1
            return days[index]
        }
        func header(at index: Int) -> some View {
            Text(letter(at: index))
                .frame(width: dayWidth)
        }
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                header(at: index)
            }
        }
        .font(.footnote)
        .padding(.vertical, 5)
    }
}

extension CalendarView {
    
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    func weeksInMonth(_ month: Int, _ year: Int) -> Int {
        guard month >= 1, month <= 12 else { fatalError() }
        let date = Date(year: year, month: month)
        let range = calendar.range(of: .weekOfMonth, in: .month, for: date)!
        return range.upperBound-range.lowerBound
    }
    
    func monthName(_ month: Int) -> String {
        let date = Date(month: month)
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        return formatter.string(from: date)
    }
}

extension CalendarView {
    
    var topInset: some View {
        Spacer().frame(height: barHeight)
    }
    
    var barHeight: CGFloat {
//        44 + proxy.safeAreaInsets.top + MetricsHeight
        44 + 50
    }

    var dayWidth: CGFloat {
        44
    }
}
