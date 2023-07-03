import Foundation

extension String {
    static var randomFoodEmoji: String {
        let foodEmojis = "🍇🍈🍉🍊🍋🍌🍍🥭🍎🍏🍐🍑🍒🍓🫐🥝🍅🫒🥥🥑🍆🥔🥕🌽🌶️🫑🥒🥬🥦🧄🧅🍄🥜🫘🌰🍞🥐🥖🫓🥨🥯🥞🧇🧀🍖🍗🥩🥓🍔🍟🍕🌭🥪🌮🌯🫔🥙🧆🥚🍳🥘🍲🫕🥣🥗🍿🧈🧂🥫🍱🍘🍙🍚🍛🍜🍝🍠🍢🍣🍤🍥🥮🍡🥟🥠🥡🦪🍦🍧🍨🍩🍪🎂🍰🧁🥧🍫🍬🍭🍮🍯🍼🥛☕🫖🍵🍶🍾🍷🍸🍹🍺🍻🥂🥃🫗🥤🧋🧃🧉🧊🥢🍽️🍴🥄"
        guard let character = foodEmojis.randomElement() else {
            return "🥕"
        }
        return String(character)
    }
}

extension String {
    func index(of string: String) -> Int? {
        guard self.contains(string) else { return nil }
        for (index, _) in self.enumerated() {
            var found = true
            for (offset, char2) in string.enumerated() {
                if self[self.index(self.startIndex, offsetBy: index + offset)] != char2 {
                    found = false
                    break
                }
            }
            if found {
                return index
            }
        }
        return nil
    }
    
    func ratio(of string: String) -> Double? {
        guard self.contains(string) else { return nil }
        return Double(string.count) / Double(count)
    }
}
