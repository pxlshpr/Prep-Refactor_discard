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

//MARK: - Calculating Portions


extension Array where Element == Double {
    var range: ClosedRange<Double> {
        guard let smallest, let largest else {
            return 0...0
        }
        return smallest...largest
    }
    
    var ascending: [Double] {
        sorted { $0 < $1 }
    }
    var smallest: Double? {
        ascending.first
    }
    
    var largest: Double? {
        ascending.last
    }
}

extension Double {
    
    func relativeScale(in array: [Double]) -> Double {
        var array = array
        guard let smallest = array.smallest, let largest = array.largest else {
            /// Test this with empty array
            return relativeScale(in: self...self)
        }
        /// If this value lies out of bounds of the array we have, append it before getting the range (so we include it)
        if self < smallest || self > largest {
            array.append(self)
        }
        return relativeScale(in: array.range)
    }
    
    func relativeScale(in range: ClosedRange<Double>) -> Double {
        
        let min: Double = 0
        let max: Double = 1.0
        
        let smallest = range.lowerBound
        let largest = range.upperBound
        
        guard self <= largest, self >= smallest else {
            return 0
        }
        
        let delta = largest-smallest
        
        guard delta > 0 else {
            return 1.0
        }
        return (self - smallest) / delta
    }
}
