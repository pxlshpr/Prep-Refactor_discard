import Foundation

extension Date {

    init?(fromCalendarDayString string: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy_MM_dd"
        guard let date = dateFormatter.date(from: string) else {
            return nil
        }
        self = date
    }

    var calendarDayString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd"
        return dateFormatter.string(from: self).lowercased()
    }

    var year: Int {
        Calendar.current.dateComponents([.year], from: self).year ?? 0
    }
    
    func longDateString(longDayNames: Bool = true) -> String {
        let formatter = DateFormatter()
        if self.year == Date().year {
            formatter.dateFormat = "EEE\(longDayNames ? "E" : "") d MMM"
        } else {
            formatter.dateFormat = "EEE\(longDayNames ? "E" : "") d MMM yy"
        }
        return formatter.string(from: self)
    }
    
    var longDateString: String {
        longDateString(longDayNames: true)
    }

    func logDateString(longDayNames: Bool = true) -> String {
        if isToday {
            "Today"
        } else if isYesterday {
            "Yesterday"
        } else if isTomorrow {
            "Tomorrow"
        } else {
            longDateString(longDayNames: longDayNames)
        }
    }
    var logDateString: String {
        logDateString()
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        startOfDay == Date().startOfDay
    }
    
    var isYesterday: Bool {
        startOfDay == Date().startOfDay.addingTimeInterval(-24 * 3600)
    }
    
    var isTomorrow: Bool {
        startOfDay == Date().startOfDay.addingTimeInterval(24 * 3600)
    }

    func moveDayBy(_ dateIncrement: Int) -> Date {
        var components = DateComponents()
        components.day = dateIncrement
        return Calendar.current.date(byAdding: components, to: self)!
    }

    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

extension Date {
    func distance(to other: Date) -> TimeInterval {
        return other.timeIntervalSinceReferenceDate - self.timeIntervalSinceReferenceDate
    }

    func advanced(by n: TimeInterval) -> Date {
        return self + n
    }
}

//TODO: Revisit this
extension Date {
    var isInWeeHours: Bool {
        Calendar.current.component(.hour, from: self) <= 5
    }
    
    var atEndOfWeeHours: Date {
        Calendar.current.date(bySettingHour: 5, minute: 55, second: 00, of: self) ?? self
    }
}

//MARK: - TimeSlots Related

extension Date {
    func timeSlot(within date: Date) -> Int {
        guard self > date.startOfDay else { return 0 }
        let difference = self.timeIntervalSince1970 - date.startOfDay.timeIntervalSince1970
        let slots = Int(difference / (15 * 60.0))
        guard slots < NumberOfTimeSlotsInADay else { return 0 }
        return slots
    }
    
    func timeForTimeSlot(_ timeSlot: Int) -> Date {
        Date(timeIntervalSince1970: startOfDay.timeIntervalSince1970 + (Double(timeSlot) * 15 * 60))
    }
}

func nearestAvailableTimeSlot(
    to timeSlot: Int,
    existingTimeSlots: [Int],
    ignoring timeSlotToIgnore: Int? = nil,
    startSearchBackwards: Bool = false,
    searchingBothDirections: Bool = false,
    doNotPassExistingTimeSlots: Bool = false
) -> Int? {
    
    func timeSlotIsAvailable(_ timeSlot: Int) -> Bool {
        if let timeSlotToIgnore {
            return timeSlot != timeSlotToIgnore && !existingTimeSlots.contains(timeSlot)
        } else {
            return !existingTimeSlots.contains(timeSlot)
        }
    }
    
    if startSearchBackwards {
        guard timeSlot >= 0 else { return nil }
        
        /// If we're starting search with timeSlot 0—we won't get a range, so check that by itself
        if timeSlot == 0, timeSlotIsAvailable(0) {
            return 0
        }
        
        /// First search backwards till start till the end
        for t in (0..<timeSlot).reversed() {
            if timeSlotIsAvailable(t) {
                return t
            }
            
            /// End early if the option to not pass any existing timeslots is given
            if doNotPassExistingTimeSlots, existingTimeSlots.contains(timeSlot) {
                return nil
            }
        }
        
        if searchingBothDirections {
            /// If we still haven't find one, go forwards
            for t in timeSlot+1..<NumberOfTimeSlotsInADay {
                if timeSlotIsAvailable(t) {
                    return t
                }
            }
        }
    } else {
        /// First search forwards till the end
        for t in timeSlot..<NumberOfTimeSlotsInADay {
            if timeSlotIsAvailable(t) {
                return t
            }
            
            /// End early if the option to not pass any existing timeslots is given
            if doNotPassExistingTimeSlots, existingTimeSlots.contains(timeSlot) {
                return nil
            }
        }
        
        if searchingBothDirections {
            /// If we still haven't find one, go backwards
            for t in (0..<timeSlot-1).reversed() {
                if timeSlotIsAvailable(t) {
                    return t
                }
            }
        }
    }
    
    return nil
}

func nearestAvailableTimeSlot(
    to time: Date,
    within date: Date,
    ignoring timeToIgnoreTimeSlotFor: Date? = nil,
    existingMealTimes: [Date],
    startSearchBackwards: Bool = false,
    searchingBothDirections: Bool = false,
    skippingFirstTimeSlot: Bool = false,
    doNotPassExistingTimeSlots: Bool = false
) -> Int? {
    let timeSlotDelta: Int
    if skippingFirstTimeSlot {
        timeSlotDelta = startSearchBackwards ? -1 : 1
    } else {
        timeSlotDelta = 0
    }
    let timeSlot = time.timeSlot(within: date) + timeSlotDelta
    let timeSlotToIgnore = timeToIgnoreTimeSlotFor?.timeSlot(within: date)
    let existingTimeSlots = existingMealTimes.compactMap {
        $0.timeSlot(within: date)
    }
    
    if startSearchBackwards {
//        cprint("🟨 getting nearestAvailableTimeSlot to \(timeSlot)")
    }

    return nearestAvailableTimeSlot(
        to: timeSlot,
        existingTimeSlots: existingTimeSlots,
        ignoring: timeSlotToIgnore,
        startSearchBackwards: startSearchBackwards,
        searchingBothDirections: searchingBothDirections,
        doNotPassExistingTimeSlots: doNotPassExistingTimeSlots
    )
}

import SwiftSugar

extension Date {
    func equalsIgnoringSeconds(_ other: Date) -> Bool {
        day == other.day
        && month == other.month
        && year == other.year
        && hour == other.hour
        && minute == other.minute
    }
}

extension Date {
    
    var d: Int { day }
    var h: Int { hour }
    var m: Int { minute }
    var atCurrentHour: Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: self)!
    }
    
    var atNextHour: Date {
        if hour == 23 {
            let nextDay = self.moveDayBy(1)
            return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: nextDay)!
        } else {
            return Calendar.current.date(bySettingHour: hour + 1, minute: 0, second: 0, of: self)!
        }
    }
    
    var atClosestHour: Date {
        if m < 30 {
            return atCurrentHour
        } else {
            return atNextHour
        }
    }
    
    func movingHourBy(_ increment: Int) -> Date {
        var components = DateComponents()
        components.hour = increment
        return Calendar.current.date(byAdding: components, to: self)!
    }
    
    func setting(
        year: Int? = nil,
        month: Int? = nil,
        day: Int? = nil,
        hour: Int? = nil,
        minute: Int? = nil
    ) -> Date {
       let calendar = Calendar.current

        var components = DateComponents()
        components.year = year ?? self.year
        components.month = month ?? self.month
        components.day = day ?? self.day
        components.hour = hour ?? self.hour
        components.minute = minute ?? self.minute

       let date = calendar.date(from: components)!
       return date
    }
}
