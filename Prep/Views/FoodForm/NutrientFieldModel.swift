import SwiftUI
import FoodDataTypes

import Observation

@Observable class NutrientFieldModel {
    
    let nutrient: Nutrient
    
    let handleNewValue: (FoodLabelValue?) -> ()
    let initialValue: FoodLabelValue?
    
    var unit: FoodLabelUnit = .g
    var internalTextfieldString: String = ""
    var internalTextfieldDouble: Double? = nil
    
    init(
        nutrient: Nutrient,
        initialValue: FoodLabelValue?,
        handleNewValue: @escaping (FoodLabelValue?) -> Void
    ) {
        self.nutrient = nutrient
        
        self.handleNewValue = handleNewValue
        self.initialValue = initialValue
        
        if let initialValue {
            internalTextfieldDouble = initialValue.amount
            internalTextfieldString = initialValue.amount.cleanWithoutRounding
        }
        self.unit = initialValue?.unit ?? nutrient.defaultFoodLabelUnit
    }

    var textFieldAmountString: String {
        get { internalTextfieldString }
        set {
            guard !newValue.isEmpty else {
                internalTextfieldDouble = nil
                internalTextfieldString = newValue
                return
            }
            guard let double = Double(newValue) else {
                return
            }
            self.internalTextfieldDouble = double
            self.internalTextfieldString = newValue
        }
    }
    
    var isRequired: Bool {
        nutrient.isMandatory
    }
    
    var value: FoodLabelValue? {
        guard let internalTextfieldDouble else { return nil }
        return FoodLabelValue(amount: internalTextfieldDouble, unit: unit)
    }
    
    var shouldDisableDone: Bool {
        if initialValue == value {
            return true
        }
        if isRequired && internalTextfieldDouble == nil {
            return true
        }
        return false
    }
    
    var shouldShowClearButton: Bool {
        !textFieldAmountString.isEmpty
    }
    
    func tappedClearButton() {
        textFieldAmountString = ""
    }
}
