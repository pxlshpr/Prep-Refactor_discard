import Foundation

struct Day2: Codable, Hashable {
    let dateString: String
    var meals: [Meal2]
    
    init(dateString: String, meals: [Meal2]) {
        self.dateString = dateString
        self.meals = meals
    }
    
    init(_ entity: DayEntity2) {
        self.init(
            dateString: entity.dateString!,
            meals: entity.meals
        )
    }
}

extension Day2: Identifiable {
    var id: String {
        dateString
    }
}

