import Foundation

extension Array {
    func shiftRight(_ amount: Int = 1) -> [Element] {
        var amount = amount
        guard count > 0 else { return self }
        assert(-count...count ~= amount, "Shift amount out of bounds")
        if amount < 0 { amount += count }  // this needs to be >= 0
        return Array(self[amount ..< count] + self[0 ..< amount])
    }

    mutating func shiftRightInPlace(_ amount: Int = 1) {
        self = shiftRight(amount)
    }
}
