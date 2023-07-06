import Foundation

extension Double {
    var formattedNutrient: String {
        let rounded: Double
        if self < 50 {
            rounded = self.rounded(toPlaces: 1)
        } else {
            rounded = self.rounded()
        }
        return rounded.formattedWithCommas
    }
    
    var formattedMealItemAmount: String {
        rounded().formattedWithCommas
    }

    var formattedNutrientValue: String {
//        guard self >= 1000 else {
//            return cleanAmount
//        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let number = NSNumber(value: Int(self))
        
        guard let formatted = formatter.string(from: number) else {
            return "\(Int(self))"
        }
        return formatted
    }

    /// no commas, but rounds it off
    var formattedMacro: String {
        "\(Int(self.rounded()))"
    }
    
    /// uses commas, rounds it off
    var formattedEnergy: String {
        let rounded = self.rounded()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let number = NSNumber(value: Int(rounded))
        
        guard let formatted = numberFormatter.string(from: number) else {
            return "\(Int(rounded))"
        }
        return formatted
    }
}

extension Double {
    var formattedWithCommas: String {
        guard self >= 1000 else {
            return cleanAmount
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(value: Int(self))
        
        guard let formatted = formatter.string(from: number) else {
            return "\(Int(self))"
        }
        return formatted
    }
}
