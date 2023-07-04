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

    var formattedEnergy: String {
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
