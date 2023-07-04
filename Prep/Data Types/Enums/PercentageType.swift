enum PercentageType {
    case empty, regular, complete, excess
}

extension PercentageType {
    init(_ value: Double) {
        if value == 0 {
            self = .empty
        } else if value == 1.0 {
            self = .complete
        } else if value > 1.0 {
            self = .excess
        } else {
            self = .regular
        }
    }
}
