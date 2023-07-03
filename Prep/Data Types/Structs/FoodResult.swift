//import Foundation
//
//struct FoodResult: Codable, Hashable, Equatable {
//    let uuid: String
//    let name: String
//    let emoji: String
//    let detail: String?
//    let brand: String?
//    
//    let energy: NutrientValue
//    let carb: Double
//    let fat: Double
//    let protein: Double
//    let micros: [NutrientValue]
//    
//    let lastUsedAt: Double
//    
//    init(_ food: FoodEntity) {
//        self.init(
//            uuid: food.uuid,
//            name: food.name,
//            emoji: food.emoji,
//            detail: food.detail,
//            brand: food.brand,
//            energy: NutrientValue(value: food.energy, energyUnit: food.energyUnit),
//            carb: food.carb,
//            fat: food.fat,
//            protein: food.protein,
//            micros: food.micros.compactMap { NutrientValue($0) },
//            lastUsedAt: food.lastUsedAt ?? 0
//        )
//    }
//    
//    init(_ food: FoodEntity) {
//        self.init(
//            uuid: food.id!.uuidString,
//            name: food.name!,
//            emoji: food.emoji!,
//            detail: food.detail,
//            brand: food.brand,
//            energy: NutrientValue(value: food.energy, energyUnit: food.energyUnit),
//            carb: food.carb,
//            fat: food.fat,
//            protein: food.protein,
//            micros: food.micros.compactMap { NutrientValue($0) },
//            lastUsedAt: food.lastUsedAt?.timeIntervalSince1970 ?? 0
//        )
//    }
//    
//    init(
//        uuid: String = "",
//        name: String = "",
//        emoji: String = "",
//        detail: String? = nil,
//        brand: String? = nil,
//        energy: NutrientValue = NutrientValue(value: 0, energyUnit: .kcal),
//        carb: Double = 0,
//        fat: Double = 0,
//        protein: Double = 0,
//        micros: [NutrientValue] = [],
//        lastUsedAt: Double = 0
//    ) {
//        self.uuid = uuid
//        self.name = name
//        self.emoji = emoji
//        self.detail = detail
//        self.brand = brand
//        self.energy = energy
//        self.carb = carb
//        self.fat = fat
//        self.protein = protein
//        self.micros = micros
//        self.lastUsedAt = lastUsedAt
//    }
//}
//
//extension FoodResult {
//    var id: String { uuid }
//}
//
//extension FoodResult: CustomStringConvertible {
//    var description: String {
//        "\(name)"
//        + "\(detail != nil ? " | \(detail!)" : "")"
//        + "\(brand != nil ? " | \(brand!)" : "")"
//    }
//}
//
//extension FoodResult {
//    
//    var foodName: String {
//        var name = "\(emoji) \(name)"
//        if let detail {
//            name += ", \(detail)"
//        }
//        if let brand {
//            name += ", \(brand)"
//        }
//        return name
//    }
//
//    var macrosChartData: [MacroValue] {
//        [
//            MacroValue(macro: .carb, value: carb),
//            MacroValue(macro: .fat, value: fat),
//            MacroValue(macro: .protein, value: protein)
//        ]
//    }
//}
