import Foundation

extension Food {
    
    /**
     Given a quantity that we are after, this returns the nutrient scale factor to apply to its nutrients in order to get scaled values.
     */
    func nutrientScaleFactor(for quantity: FoodQuantity) -> Double? {
        
        guard let amountQuantity, quantity.food.id == self.id else { return nil }
        
        /// now convert the quantity we're after into the units that the food amount is described in
        guard let converted = amountQuantity.convert(to: quantity.unit) else { return nil }
        /**
         So now we have the following:
         amountQuantity.value foodAmount = converted.value unit
         y foodAmount = quantity.value unit
         
         solve for y, and the scaleFactor is y / 1
         */
        let y = (quantity.value * amountQuantity.value) / converted.value
        return y/amountQuantity.value
    }
    
    /**
     Returns the `FoodQuantity` that represents what the nutrients have been described for.
     
     Note: If the unit is `.serving` and we have the `servingQuantity: FoodQuantity?`, then that is returned—otherwise we simply return the `FoodQuantity` in terms of `.serving`s.
     */
    var amountQuantity: FoodQuantity? {
        switch amount.unitType {
        case .weight, .volume, .size:
            guard let unit = FoodQuantity.Unit(foodValue: amount, in: self) else { return nil }
            return FoodQuantity(value: amount.value, unit: unit, food: self)
        case .serving:
            return servingQuantity ?? FoodQuantity(value: amount.value, unit: .serving, food: self)
        }
    }
    
    var servingQuantity: FoodQuantity? {
        guard let serving = serving,
              let unit = FoodQuantity.Unit(foodValue: serving, in: self)
        else { return nil }
        return FoodQuantity(value: amount.value * serving.value, unit: unit, food: self)
    }
    
    /**
     Returns the `FoodQuantity` that is best used as a default for this food.
     
     Usually reverts to simply returning the `amountQuantity` except for certain circumstances, such as:
     - If there is only one size for this food, returns 1 x that size.
     */
    var defaultQuantity: FoodQuantity? {
        if !usesSizeForAmountOrServing, let onlySize, serving == nil {
            return FoodQuantity(1, onlySize.id, self)
        }
        
        return amountQuantity
    }
}

extension Food {
    var hasOneSize: Bool {
        sizes.count == 1
    }
    
    var onlySize: FoodSize? {
        guard hasOneSize else { return nil }
        return sizes.first
    }
    
    var usesSizeForAmountOrServing: Bool {
        amount.unitType == .size || serving?.unitType == .size
    }
}
