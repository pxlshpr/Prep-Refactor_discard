import SwiftUI

import FoodDataTypes

extension NutrientMeter {
    struct Model {
        
        var component: NutrientMeterComponent

        /// Used to convey that this is for a component that has been generated (either an implicit daily goal or a meal subgoal),
        /// as we may want to style it differently
        var isGenerated: Bool
        
        var goalLower: Double?
        var goalUpper: Double?

        var planned: Double
        var eaten: Double?
        var increment: Double?

        //TODO: Remove this
        var burned: Double
        
        init(
            component: NutrientMeterComponent,
            isGenerated: Bool = false,
            goalLower: Double? = nil,
            goalUpper: Double? = nil,
            burned: Double = 0,
            planned: Double,
            increment: Double
        ) {
            self.component = component
            self.isGenerated = isGenerated
            self.goalLower = goalLower
            self.goalUpper = goalUpper
            self.burned = burned
            self.planned = planned
            self.eaten = nil
            self.increment = increment
        }
        
        init(
            component: NutrientMeterComponent,
            isGenerated: Bool = false,
            goalLower: Double? = nil,
            goalUpper: Double? = nil,
            burned: Double = 0,
            planned: Double,
            eaten: Double
        ) {
            self.component = component
            self.isGenerated = isGenerated
            self.goalLower = goalLower
            self.goalUpper = goalUpper
            self.burned = burned
            self.planned = planned
            self.eaten = eaten
            self.increment = nil
        }
        
        init(
            component: NutrientMeterComponent,
            isGenerated: Bool = false,
            customPercentage: Double,
            customValue: Double
        ) {
            self.component = component
            self.isGenerated = isGenerated
            self.goalLower = nil
            self.goalUpper = nil
            self.burned = 0
            self.planned = customPercentage == 0 ? 0 : (customValue / customPercentage)
            self.eaten = customValue
            self.increment = nil
        }
    }
}

extension NutrientMeter.Model {
    var remainingString: String {
        return "TODO"
//        guard let goal else { return "" }
//        return "\(Int(goal + burned - planned - (increment ?? 0)))"
    }
    
    var goalString: String {
        return "TODO"
//        guard let goal else { return "" }
//        return "\(Int(goal))"
    }
    
    var burnedString: String {
        "\(Int(burned))"
    }
    
    var foodString: String {
        "\(Int(planned + (increment ?? 0)))"
    }
    
//    var incrementString: String {
//        "\(Int(increment ?? 0))"
//    }
}

//extension NutrientMeter2.Model: Hashable {
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(component)
//        hasher.combine(goalLower)
//        hasher.combine(goalUpper)
//        hasher.combine(burned)
//        hasher.combine(planned)
//        hasher.combine(eaten)
//        hasher.combine(increment)
//    }
//}
//
//extension NutrientMeter2.Model: Equatable {
//    static func ==(lhs: NutrientMeter2.Model, rhs: NutrientMeter2.Model) -> Bool {
//        lhs.hashValue == rhs.hashValue
//    }
//}

extension NutrientMeter.Model {
    var haveGoal: Bool {
        goalLower != nil || goalUpper != nil
    }
    
    var showingIncrement: Bool {
        increment != nil
    }
    
    var highestGoal: Double? {
        goalUpper ?? goalLower
    }
    
    var totalGoal: Double {
        /// Returned `planned` when we have no goal so that the entire meter becomes the planned amount
        guard let highestGoal else {
            return planned
        }
        return highestGoal + burned
    }
    
    var goalBoundsType: GoalBoundsType {
        if goalLower != nil {
            if goalUpper != nil {
                return .lowerAndUpper
            } else {
                return .lowerOnly
            }
        } else if goalUpper != nil {
            return .upperOnly
        } else {
            return .none
        }
    }
    

    var eatenPercentageType: PercentageType {
        guard preppedPercentageType != .excess else {
            return .excess
        }
        return PercentageType(eatenPercentage)
    }
    
    var eatenPercentage: Double {
        guard let eaten = eaten, totalGoal != 0 else { return 0 }
        //        guard let eaten = eaten?.wrappedValue, totalGoal != 0 else { return 0 }
        if preppedPercentage < 1 {
            return eaten / totalGoal
        } else {
            guard planned != 0 else { return 0 }
            return eaten / planned
        }
    }
    
    var normalizdEatenPercentage: Double {
        if eatenPercentage < 0 {
            return 0
        } else if eatenPercentage > 1 {
            return 1.0/eatenPercentage
        } else {
            return eatenPercentage
        }
    }
    
    var preppedPercentageForMeter: Double {
        /// Choose greater of preppedPercentage or prepped/(prepped + increment)
        if let increment = increment,
           totalGoal + increment > 0,
           planned / (totalGoal + increment) > preppedPercentage
        {
            return planned / (planned + increment)
        } else {
            return preppedPercentage
        }
    }
    
    var preppedPercentage: Double {
        guard totalGoal != 0 else { return 0 }
        
        let total: Double
        if let increment = increment,
           planned + increment > totalGoal
        {
            //        if let increment = increment?.wrappedValue,
            //           food + increment > totalGoal
            //        {
            total = planned + increment
        } else {
            total = totalGoal
        }
        
        return planned / total
    }

    var percentageType: PercentageType {
        if let _ = increment {
            return incrementPercentageType
        } else {
            return preppedPercentageType
        }
    }
}

extension NutrientMeter.Model {
    
    var preppedColor: Color {
        switch percentageType {
        case .empty:
            return Color("StatsEmptyFill")
        case .regular:
            return component.preppedColor
        case .complete:
            return haveGoal ? Colors.Complete.placeholder : component.preppedColor
        case .excess:
            return haveGoal ? Colors.Excess.placeholder : component.preppedColor
        }
    }
    
    var incrementColor: Color {
        switch incrementPercentageType {
        case .empty:
            return Color("StatsEmptyFill")
        case .regular:
            return component.eatenColor
        case .complete:
            return haveGoal ? Colors.Complete.fill : component.eatenColor
        case .excess:
            return haveGoal ? Colors.Excess.fill : component.eatenColor
        }
    }
    
    var eatenColor: Color {
        guard preppedPercentageType != .complete else {
            return haveGoal ? Colors.Complete.fill : component.eatenColor
        }
        
        switch eatenPercentageType {
//        case .empty:
//            return Color("StatsEmptyFill", bundle: .module)
        case .regular, .empty:
            return component.eatenColor
        case .complete:
            return haveGoal ? Colors.Complete.fill : component.eatenColor
        case .excess:
            return haveGoal ? Colors.Excess.fill : component.eatenColor
        }
    }
    
    var textColor: Color {
        guard preppedPercentageType != .complete else {
            return haveGoal ? Colors.Complete.fill : component.eatenColor
        }
        
        /// Override the empty color only
        if eatenPercentageType == .empty { return component.eatenColor }
        return eatenColor
    }
}

extension NutrientMeter.Model {
    struct Colors {
        struct Complete {
            static let placeholder = Color("StatsCompleteFillExtraNew")
            static let fill = Color("StatsCompleteFill")
            static let text = Color("StatsCompleteText")
            static let textDarker = Color("StatsCompleteTextExtra")
        }
        
        struct Excess {
            static let placeholder = Color("StatsExcessFillExtra")
            static let fill = Color("StatsExcessFill")
            static let text = Color("StatsExcessText")
            static let textDarker = Color("StatsExcessTextExtra")
        }
        
        struct Empty {
            static let fill = Color("StatsEmptyFill")
            static let text = Color("StatsEmptyText")
            static let textLighter = Color("StatsEmptyTextSecondary")
        }
    }
}

extension NutrientMeter.Model {
    
    var labelTextColor: Color {
        guard haveGoal else { return component.textColor }
        switch percentageType {
        case .empty:
            return Colors.Empty.text
        case .regular:
            return component.textColor
        case .complete:
            return Colors.Complete.text
        case .excess:
            return Colors.Excess.text
        }
    }
    
}
