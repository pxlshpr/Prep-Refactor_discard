import Foundation

struct Day: Codable, Hashable {
    let dateString: String
    var meals: [Meal]
    
    init(dateString: String, meals: [Meal]) {
        self.dateString = dateString
        self.meals = meals
    }
    
    init(_ entity: DayEntity) {
        self.init(
            dateString: entity.dateString!,
            meals: entity.meals
        )
    }
}

extension Day: Identifiable {
    var id: String {
        dateString
    }
}

