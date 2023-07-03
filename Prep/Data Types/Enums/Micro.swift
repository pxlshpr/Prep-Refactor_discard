//import Foundation
//import FoodDataTypes
//
//enum Micro: Int, CaseIterable, Codable {
//    
//    /// Fats
//    case saturatedFat = 1
//    case monounsaturatedFat
//    case polyunsaturatedFat
//    case transFat
//    case cholesterol
//    
//    /// Fibers
//    case dietaryFiber = 50
//    case solubleFiber
//    case insolubleFiber
//    
//    /// Sugars
//    case sugars = 100
//    case addedSugars
//    case sugarAlcohols
//    
//    /// Minerals
//    case calcium = 150
//    case chloride
//    case chromium
//    case copper
//    case iodine
//    case iron
//    case magnesium
//    case manganese
//    case molybdenum
//    case phosphorus
//    case potassium
//    case selenium
//    case sodium
//    case zinc
//    
//    /// Vitamins
//    case vitaminA = 200
//    case vitaminB1_thiamine
//    case vitaminB2_riboflavin
//    case vitaminB3_niacin
//    case vitaminB5_pantothenicAcid
//    case vitaminB6_pyridoxine
//    case vitaminB7_biotin
//    case vitaminB9_folate
//    case vitaminB9_folicAcid
//    case vitaminB12_cobalamin
//    case vitaminC_ascorbicAcid
//    case vitaminD_calciferol
//    case vitaminE
//    case vitaminK1_phylloquinone
//    case vitaminK2_menaquinone
//    
//    case choline
//    
//    /// Misc
//    case caffeine = 250
//    case ethanol
//    case taurine
//    case polyols
//    case gluten
//    case starch
//    case salt
//    case creatine
//    
//    /// **For internal-use only**
//    case energyWithoutDietaryFibre
//    case water = 500
//    case freeSugars
//    case ash
//    
//    /// Vitamin Related
//    case preformedVitaminARetinol
//    case betaCarotene
//    case provitaminABetaCaroteneEquivalents
//    
//    case niacinDerivedEquivalents
//    
//    case totalFolates
//    case dietaryFolateEquivalents
//    case alphaTocopherol
//    
//    /// Essential Amino Acids
//    case tryptophan
//    
//    /// Fatty Acids
//    case linoleicAcid
//    case alphaLinolenicAcid
//    case eicosapentaenoicAcid
//    case docosapentaenoicAcid
//    case docosahexaenoicAcid
//}
//
//extension Micro {
//    var name: String {
//        switch self {
//        case .saturatedFat:
//            return "Saturated Fat"
//        case .monounsaturatedFat:
//            return "Monounsaturated Fat"
//        case .polyunsaturatedFat:
//            return "Polyunsaturated Fat"
//        case .transFat:
//            return "Trans Fat"
//        case .cholesterol:
//            return "Cholesterol"
//        case .dietaryFiber:
//            return "Dietary Fiber"
//        case .solubleFiber:
//            return "Soluble Fiber"
//        case .insolubleFiber:
//            return "Insoluble Fiber"
//        case .sugars:
//            return "Sugars"
//        case .addedSugars:
//            return "Added Sugars"
//        case .sugarAlcohols:
//            return "Sugar Alcohols"
//        case .calcium:
//            return "Calcium"
//        case .chloride:
//            return "Chloride"
//        case .chromium:
//            return "Chromium"
//        case .copper:
//            return "Copper"
//        case .iodine:
//            return "Iodine"
//        case .iron:
//            return "Iron"
//        case .magnesium:
//            return "Magnesium"
//        case .manganese:
//            return "Manganese"
//        case .molybdenum:
//            return "Molybdenum"
//        case .phosphorus:
//            return "Phosphorus"
//        case .potassium:
//            return "Potassium"
//        case .selenium:
//            return "Selenium"
//        case .sodium:
//            return "Sodium"
//        case .zinc:
//            return "Zinc"
//            
//            
//        case .vitaminA:
//            return "Vitamin A"
//        case .vitaminB1_thiamine:
//            return "Thiamine (B1)"
//        case .vitaminB2_riboflavin:
//            return "Riboflavin (B2)"
//        case .vitaminB3_niacin:
//            return "Niacin (B3)"
//        case .vitaminB5_pantothenicAcid:
//            return "Pantothenic Acid (B5)"
//        case .vitaminB6_pyridoxine:
//            return "Pyridoxine (B6)"
//        case .vitaminB7_biotin:
//            return "Biotin (B7)"
//        case .vitaminB9_folate:
//            return "Folate (B9)"
//        case .vitaminB9_folicAcid:
//            return "Folic Acid (B9)"
//        case .vitaminB12_cobalamin:
//            return "Cobalamin (B12)"
//        case .vitaminC_ascorbicAcid:
//            return "Vitamin C"
//        case .vitaminD_calciferol:
//            return "Vitamin D"
//        case .vitaminE:
//            return "Vitamin E"
//        case .vitaminK1_phylloquinone:
//            return "Vitamin K1"
//        case .vitaminK2_menaquinone:
//            return "Vitamin K2"
//            
//        case .caffeine:
//            return "Caffeine"
//        case .ethanol:
//            return "Ethanol"
//        case .taurine:
//            return "Taurine"
//        case .polyols:
//            return "Polyols"
//        case .gluten:
//            return "Gluten"
//        case .starch:
//            return "Starch"
//        case .salt:
//            return "Salt"
//        case .creatine:
//            return "Creatine"
//            
//        case .choline:
//            return "Choline"
//
//        case .energyWithoutDietaryFibre:
//            return "Energy without Dietary Fibre"
//        case .water:
//            return "Water"
//        case .freeSugars:
//            return "Free Sugars"
//            
//        case .ash:
//            return "Ash"
//        case .preformedVitaminARetinol:
//            return "Preformed Vitamin A (Retinol)"
//        case .betaCarotene:
//            return "Beta-carotene"
//        case .provitaminABetaCaroteneEquivalents:
//            return "Provitamin A (b-carotene equivalents)"
//            
//        case .niacinDerivedEquivalents:
//            return "Niacin Derived Equivalents"
//        case .totalFolates:
//            return "Total Folates"
//        case .dietaryFolateEquivalents:
//            return "Dietary Folate Equivalents"
//        case .alphaTocopherol:
//            return "Alpha Tocopherol"
//        case .tryptophan:
//            return "Tryptophan"
//        case .linoleicAcid:
//            return "Linoleic Acid"
//        case .alphaLinolenicAcid:
//            return "Alpha-linolenic Acid"
//        case .eicosapentaenoicAcid:
//            return "Eicosapentaenoic Acid"
//        case .docosapentaenoicAcid:
//            return "Docosapentaenoic Acid"
//        case .docosahexaenoicAcid:
//            return "Docosahexaenoic Acid"
//        }
//    }
//}
//
//extension Micro {
//    var group: MicroGroup? {
//        switch self {
//        case .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .transFat, .cholesterol:
//            return .fats
//        case .dietaryFiber, .solubleFiber, .insolubleFiber:
//            return .fibers
//        case .sugars, .addedSugars, .sugarAlcohols:
//            return .sugars
//        case .calcium, .chloride, .chromium, .copper, .iodine, .iron, .magnesium, .manganese, .molybdenum, .phosphorus, .potassium, .selenium, .sodium, .zinc:
//            return .minerals
//        case .vitaminA, .vitaminB1_thiamine, .vitaminB2_riboflavin, .vitaminB3_niacin, .vitaminB5_pantothenicAcid, .vitaminB6_pyridoxine, .vitaminB7_biotin, .vitaminB9_folate, .vitaminB9_folicAcid, .vitaminB12_cobalamin, .vitaminC_ascorbicAcid, .vitaminD_calciferol, .vitaminE, .vitaminK1_phylloquinone, .vitaminK2_menaquinone:
//            return .vitamins
//        case .caffeine, .ethanol, .taurine, .polyols, .gluten, .starch, .salt, .choline, .creatine:
//            return .misc
//        default:
//            return nil
//        }
//    }
//    
//    var defaultUnit: NutrientUnit {
//        units.first ?? .g
//    }
//
//    var units: [NutrientUnit] {
//        switch self {
//        case .cholesterol, .calcium, .chloride, .copper, .iron, .magnesium, .manganese, .phosphorus, .potassium, .sodium, .zinc, .vitaminC_ascorbicAcid, .vitaminB6_pyridoxine, .choline, .vitaminB5_pantothenicAcid, .vitaminB2_riboflavin, .vitaminB1_thiamine, .caffeine, .vitaminK2_menaquinone, .taurine:
//            return [.mg]
//        case .chromium, .iodine, .molybdenum, .selenium, .vitaminB12_cobalamin, .vitaminK1_phylloquinone, .vitaminB7_biotin, .vitaminB9_folicAcid:
//            return [.mcg]
//        case .vitaminA:
//            return [.mcgRAE, .IU]
//        case .vitaminD_calciferol:
//            return [.mcg, .IU]
//        case .vitaminE:
//            return [.mgAT, .IU]
//        case .vitaminB9_folate:
//            return [.mcgDFE, .mcg]
//        case .vitaminB3_niacin:
//            return [.mgNE, .mg]
//        default:
//            return [.g]
//        }
//    }
//    var supportedNutrientUnits: [NutrientUnit] {
//        var units = units.map {
//            $0
//        }
//        /// Allow percentage values for `mineral`s and `vitamin`s
//        if supportsPercentages {
//            units.append(.p)
//        }
//        return units
//    }
//
//    var supportsPercentages: Bool {
//        group?.supportsPercentages ?? false
//    }
//
//    var supportedFoodLabelUnits: [FoodLabelUnit] {
//        supportedNutrientUnits.map { $0.foodLabelUnit ?? .g}
//            .removingDuplicates()
//    }
//}
//
//extension Micro: Identifiable {
//    var id: Int { rawValue }
//}
