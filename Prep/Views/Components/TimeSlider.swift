import SwiftUI
import OSLog

import SwiftHaptics

struct TimeSlider: View {

    let date: Date
    let existingTimeSlots: [Int]
    @Binding var currentTime: Date
    @State var currentTimeSlot: Int
    
    @State var spacing: CGFloat = 0.5
    let barHeight: CGFloat = 50.0
    
    @State var sliderWidth: CGFloat = 0
    @State var buttonSize: CGSize = .zero
    @State var markersRowHeight: CGFloat = 0

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                timeButtonRow
                connectorRowPlaceholder
                slider
                    .frame(height: barHeight)
                    .readSize { size in
                        self.sliderWidth = size.width
                    }
                markersRow
            }
            connectorLayer
        }
        .gesture(dragGesture)
        .onTapGesture { tappedX($0.x) }
        .onChange(of: currentTime) { oldValue, newValue in
            withAnimation(.interactiveSpring()) {
                currentTimeSlot = newValue.timeSlot(within: date)
            }
        }
    }
    
    var connectorLayer: some View {
        var connector: some View {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: max(width(for: sliderWidth), 0))
                .cornerRadius(1, corners: [.bottomRight, .bottomLeft])
        }
        
        var offsetX: CGFloat {
            zeroPosition + minXForCurrentTimeSlot + (currentTimeSlot == 0 ? 0 : spacing)
        }
        
        return VStack(spacing: 0) {
            Color.clear
                .frame(height: max(buttonSize.height - 1, 0))
            connector
                .frame(height: 20 + barHeight)
                .offset(x: offsetX)
            Color.clear
                .frame(height: markersRowHeight)
        }
    }

    func tappedX(_ x: CGFloat) {
        let tappedTimeSlot = timeSlot(for: x)
//        if let timeSlot = nearestAvailableTimeSlot(to: tappedTimeSlot) {
        if let timeSlot = nearestAvailableTimeSlot(
            to: tappedTimeSlot,
            existingTimeSlots: existingTimeSlots,
            ignoring: currentTimeSlot,
            searchingBothDirections: true
        ) {
            withAnimation(.interactiveSpring()) {
                Haptics.feedback(style: .soft)
                self.currentTimeSlot = timeSlot
                self.currentTime = date.timeForTimeSlot(timeSlot)
            }
        }
    }
    
//    func nearestAvailableTimeSlot(to timeSlot: Int) -> Int? {
//
//        func timeSlotIsAvailable(_ timeSlot: Int) -> Bool {
//            timeSlot != self.currentTimeSlot && !existingTimeSlots.contains(timeSlot)
//        }
//
//        /// First search forwards till the end
//        for t in timeSlot..<K.numberOfSlots {
//            if timeSlotIsAvailable(t) {
//                return t
//            }
//        }
//        /// If we still haven't find one, go backwards
//        for t in (0..<timeSlot-1).reversed() {
//            if timeSlotIsAvailable(t) {
//                return t
//            }
//        }
//        return nil
//    }

    var dragGesture: some Gesture {
        func changed(_ value: DragGesture.Value) {
            let timeSlot = timeSlot(for: value.location.x)
            if timeSlot != self.currentTimeSlot, !existingTimeSlots.contains(timeSlot) {
                Haptics.selectionFeedback()
                self.currentTimeSlot = timeSlot
                self.currentTime = date.timeForTimeSlot(timeSlot)
            }
        }

        func ended(_ value: DragGesture.Value) { }

        return DragGesture()
            .onChanged(changed)
            .onEnded(ended)
    }
    
    func width(for width: CGFloat) -> CGFloat {
        let available = (width - (spacing * (CGFloat(NumberOfTimeSlotsInADay) - 1.0)))
        return max(available / CGFloat(NumberOfTimeSlotsInADay), 0)
    }
    
    func minX(for timeSlot: Int) -> CGFloat {
        (width(for: sliderWidth) * CGFloat(timeSlot)) + (spacing * max(CGFloat(timeSlot - 1), 0))
    }
    
    var minXForCurrentTimeSlot: CGFloat {
        minX(for: self.currentTimeSlot)
    }
    
    var zeroPosition: CGFloat {
        -(sliderWidth / 2.0) + width(for: sliderWidth) / 2.0
    }
    
    var markersRow: some View {
        
        func offsetX(for timeSlot: Int) -> CGFloat {
            zeroPosition + minX(for: timeSlot) + (timeSlot == 0 ? 0 : spacing)
        }
        
        let markers: [(Int, String)] = [
            (0, "12a"),
            (3, ""),
            (6, "6a"),
            (9, ""),
            (12, "12p"),
            (15, ""),
            (18, "6p"),
            (21, ""),
            (24, "12a"),
            (27, ""),
            (30, "6a"),
        ]
        
        return ZStack {
            ForEach(markers.indices, id: \.self) { index in
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(.systemFill))
                        .frame(width: markers[index].1.isEmpty ? 0.75 : 1.0, height: 5)
                        .offset(x: offsetX(for: markers[index].0 * 4))
                        .opacity(markers[index].0 == 30 ? 0 : 1)
                    Text(markers[index].1)
                        .font(.caption2)
                        .foregroundStyle(Color(.secondaryLabel))
                        .offset(x: offsetX(for: markers[index].0 * 4))
                }
            }
            .readSize { size in
                markersRowHeight = size.height
            }
        }
    }
    
    var connectorRowPlaceholder: some View {
        var connector: some View {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: max(width(for: sliderWidth), 0), height: 20)
        }
        
        var offsetX: CGFloat {
            zeroPosition + minXForCurrentTimeSlot + (currentTimeSlot == 0 ? 0 : spacing)
        }
        
        return ZStack {
            connector
                .offset(x: offsetX)
                .opacity(0)
        }
//        .frame(width: sliderWidth, height: 20)
    }
    
    var timeButtonRow: some View {
        var button: some View {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(timeString)
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                Text(amPmString)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.accentColor.gradient)
            )
        }
        
        var offsetX: CGFloat {
            let minX = zeroPosition + (buttonSize.width / 2.0) - (width(for: sliderWidth) * 2)
            let maxX = (zeroPosition + sliderWidth) - (buttonSize.width / 2.0) + (width(for: sliderWidth) * 2)
            let x = zeroPosition + minXForCurrentTimeSlot + (currentTimeSlot == 0 ? 0 : spacing)
            return min(max(x, minX), maxX)
        }
        
        return ZStack {
            button
            .offset(x: offsetX)
            .readSize { size in
                buttonSize = size
            }
        }
//        .frame(width: sliderWidth)
    }

    var timeString: String {
//        timeString(for: self.currentTimeSlot)
        timeString(for: self.currentTime)
    }
    
    var amPmString: String {
//        amPmString(for: self.currentTimeSlot)
        amPmString(for: self.currentTime)
    }
    
    func date(for timeslot: Int) -> Date {
        let timeInterval = Double(currentTimeSlot) * 15 * 60
        return date.startOfDay.addingTimeInterval(timeInterval)
    }
    func timeString(for timeslot: Int) -> String {
        timeString(for: date(for: timeslot))
    }
    
    func timeString(for time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: time)
    }

    func amPmString(for timeslot: Int) -> String {
        amPmString(for: date(for: timeslot))
    }

    func amPmString(for time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: time).lowercased()
    }

    func timeSlot(for x: CGFloat) -> Int {
        let width = width(for: sliderWidth)
        let timeSlot = Int(x / (width + spacing))
        return min(max(timeSlot, 0), NumberOfTimeSlotsInADay - 1)
    }

    var slider: some View {
        
        var bars: some View {
            return GeometryReader { proxy in
                ZStack {
                    HStack(spacing: spacing) {
                        ForEach(0..<NumberOfTimeSlotsInADay, id: \.self) {
                            rectangle(at: $0)
                                .frame(width: width(for: proxy.size.width), height: barHeight)
                        }
                    }
                }
            }
        }
        
        var solidColor: some View {
            Color(.secondarySystemFill)
        }
        
        return bars
//        return solidColor
    }
    
    
    @ViewBuilder
    func rectangle(at index: Int) -> some View {
        if index == currentTimeSlot {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .foregroundStyle(Color(.secondarySystemFill))
        } else if existingTimeSlots.contains(index) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .foregroundStyle(Color(.secondaryLabel))
        } else {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .foregroundStyle(Color(.secondarySystemFill))
//                .onTapGesture {
//                    if !existingTimeSlots.contains(index) {
//                        tapped(index)
//                    }
//                }
        }
    }
}
