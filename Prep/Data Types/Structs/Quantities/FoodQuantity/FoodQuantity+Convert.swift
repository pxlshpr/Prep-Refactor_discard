import Foundation

import FoodDataTypes

extension FoodQuantity.Unit {
    var volumePrefixScale: Double {
        guard let sizeVolumePrefixExplicitUnit else { return 1 }
        return size?.volumePrefixScale(for: sizeVolumePrefixExplicitUnit) ?? 1
    }
}
extension FoodQuantity {
    
    func convert(to unit: Unit) -> FoodQuantity? {
        
        let converted: Double?
        
        switch self.unit {
            
        case .weight(let weightUnit):
            let weight = WeightQuantity(value: value, unit: weightUnit)
            converted = convertWeight(weight, toUnit: unit)
            
        case .volume(let volumeUnit):
            let volume = VolumeQuantity(value: value, unit: volumeUnit)
            converted = convert(volume, to: unit)
            
        case .serving:
            converted = convertServings(value, to: unit)

        case .size(let size, let volumeUnit):
            let sizeQuantity = SizeQuantity(value, size, volumeUnit)
            converted = convert(sizeQuantity, to: unit)
        }
        
        guard let converted else { return nil }
        
//        let scale = unit.volumePrefixScale
        let scale = 1.0

        return FoodQuantity(
            value: converted * scale,
            unit: unit,
            food: self.food
        )
    }
}

extension FoodQuantity {
    func convertServings(_ quantity: Double, to unit: Unit) -> Double? {
        
        let converted: Double?
        switch unit {
            
        case .weight(let weightUnit):
            /// Get the weight of 1 serving
            guard let servingWeight = food.servingWeight else { return nil}
            /// Now convert it to the weight unit provided
            converted = servingWeight.convert(to: weightUnit)
            
        case .volume(let volumeUnit):
            /// Get the volume of 1 serving
            guard let servingVolume = food.servingVolume else { return nil}
            /// Now convert it to the weight unit provided
            converted = servingVolume.convert(to: volumeUnit)
            
        case .size(let size, let volumeUnit):
            converted = food.quantityPerServing(of: size, with: volumeUnit)
            
        case .serving:
            return 1
        }
        /// Now multiply it by the number of servings we're converting
        guard let converted else { return nil }
        return converted * quantity
    }
}

extension FoodQuantity {
    
    func convert(_ sizeQuantity: SizeQuantity, to unit: Unit) -> Double? {
        
        /// This is used to hold the unit value of this size in the provided unit (ie. how much of that unit 1 of this size equals)
        let unitValue: Double
        
        switch unit {
        case .weight(let weightUnit):
            // ✅ Tests Passing
            /// Get the unit weight of the size (how much 1 unit of it weighs)
            guard let unitWeight = sizeQuantity.size.unitWeight(in: food) else { return nil }
            /// Convert this to the weight unit provided
            unitValue = unitWeight.convert(to: weightUnit)

        case .volume(let volumeUnit):
            // ✅ Tests Passing
            /// Get the unit volume of the size (how much the volume of 1 unit of it is)
            guard let unitVolume = sizeQuantity.size.unitVolume(in: food) else { return nil }
            /// Convert this to the volume unit provided
            unitValue = unitVolume.convert(to: volumeUnit)

        case .size(let size, let volumeUnit):

            guard let quantityPerSize = sizeQuantity.size.quantityPerSize(of: size, in: food) else { return nil }

            let volumePrefixScale = sizeQuantity.volumePrefixScale
            
            /// This is the value in the default volumePrefixSize of the target size
            let value = (quantityPerSize * sizeQuantity.value) / volumePrefixScale

            /// Now convert it to the size provided
            let targetScale = size.volumePrefixScale(for: volumeUnit)
            let scaledValue = value * targetScale

            return scaledValue

        case .serving:
            guard let quantityPerServing = food
                .quantityPerServing(
                    of: sizeQuantity.size,
                    with: sizeQuantity.volumeUnit
                ) else { return nil }
            
            guard quantityPerServing > 0 else { return nil }
            return value / quantityPerServing
        }
        
        /// Now scale the number of sizes provided to make it match what the size specifies
        let scale = sizeQuantity.volumePrefixScale
        guard scale > 0 else { return nil }
        let scaledSizeValue = sizeQuantity.value / scale
        /// Use that and the unit weight (in the provided weight unit) to calculate the weight
        return unitValue * scaledSizeValue
    }
    
    // ✅ Tests Passing
    func convert(_ volume: VolumeQuantity, to unit: Unit) -> Double? {
        switch unit {
            
        case .weight(let weightUnit):
            // ✅ Tests Passing
            guard let density = food.density else { return nil }
            /// Volume → Weight
            let weight = density.convert(volume: volume)
            /// Volume → VolumeUnit
            return weight.convert(to: weightUnit)

        case .volume(let volumeUnit):
            // ✅ Tests Passing
            return volume.convert(to: volumeUnit)

        case .size(let size, let volumeUnit):
            // ✅ Tests Passing
            guard let unitVolume = size.unitVolume(in: food) else { return nil }
            let converted = unitVolume.convert(to: volume.unit)
            guard converted > 0 else { return nil }
            let volume = volume.value / converted
            return volume * size.volumePrefixScale(for: volumeUnit)

        case .serving:
            // ✅ Tests Passing
            guard let servingVolume = food.servingVolume else { return nil }
            let converted = servingVolume.convert(to: volume.unit)
            guard converted > 0 else { return nil }
            return value / converted
        }
    }
}

extension FoodQuantity.Unit {
    var size: FoodQuantity.Size? {
        switch self {
        case .size(let size, _):
            return size
        default:
            return nil
        }
    }
}

extension FoodQuantity.Size {
    
    func isParent(of size: FoodQuantity.Size) -> Bool {
        guard let sizeUnit = self.unit.size else { return false }
        if sizeUnit == size {
            return true
        } else {
            return sizeUnit.isParent(of: size)
        }
    }
    
//    func quantityPerSize(of size: FoodQuantity.Size) -> Double? {
//        guard unitValue > 0 else {
//            return nil
//        }
//
//        guard let sizeUnit = self.unit.size else {
//            if size.unit.size != nil {
//                return size.quantityPerSize(of: self)
//            } else {
//                return nil
//            }
//        }
//        if sizeUnit == size {
//            let scale = self.unit
//                .sizeVolumePrefixExplicitUnit?
//                .scale(against: size.volumeUnit) ?? 1
//            return 1 / unitValue / scale
//        } else {
//            /// Recursively keep drilling down till we hit the size unit
//            guard let unitSizeValue = sizeUnit.quantityPerSize(of: size) else { return nil }
//            return unitSizeValue / unitValue
//        }
//    }
}

//extension FormSize {
//    /**
//     Returns how many servings this size represents, if applicable. Drills down to the base size if necessary.
//
//     Basic case:
//     - 3 x **balls** = 1 serving
//     *This would imply that 1 ball is 1/3 servings*
//
//     Hierarchical case:
//     - 2 x **sleeves** = 16 balls
//     - 3 x balls = 1 serving
//     *This implies that 1 sleeve would be  2.5 servings*
//     */
//    var unitServings: Double? {
//        guard isServingBased, let amount, let quantity else { return nil }
//        if unit == .serving {
//            return amount / quantity
//        } else if case .size(let sizeUnit, let volumeUnit) = unit {
//            guard let unitServings = sizeUnit.unitServings else {
//                return nil
//            }
//            return (unitServings * amount) / quantity
//
//            //TODO: What do we do about the volumeUnit
//        } else {
//            return nil
//        }
//    }
//
//    /**
//     Returns the quantity representing how much 1 of this size weights, if applicable. Drills down to the base size if necessary.
//     This is **Quarantined**
//     */
//    func unitWeightQuantity(in food: FoodEntity) -> FoodQuantity? {
//        guard let amount, let quantity else { return nil }
//
//        switch unit {
//        case .weight(let weightUnit):
//            return FoodQuantity(
//                amount: (amount / quantity),
//                unit: .weight(weightUnit),
//                food: food
//            )
//
//        case .serving:
//            guard let servingWeightQuantity = food.servingWeightQuantity else {
//                return nil
//            }
//
//            return FoodQuantity(
//                amount: (servingWeightQuantity.value * amount) / quantity,
//                unit: servingWeightQuantity.unit,
//                food: food
//            )
//
//        case .size(let sizeUnit, let volumeUnit):
//            guard let unitWeightQuantity = sizeUnit.unitWeightQuantity(in: food) else {
//                return nil
//            }
//            return FoodQuantity(
//                amount: (unitWeightQuantity.value * amount) / quantity,
//                unit: unitWeightQuantity.unit,
//                food: food
//            )
//
//            //TODO: What do we do about the volumeUnit
//        default:
//            return nil
//        }
//    }
//
//    /**
//     Returns the quantity representing how much 1 of this size weights, if applicable. Drills down to the base size if necessary.
//     */
//    func unitWeight(in food: FoodEntity) -> WeightQuantity? {
//        guard let amount, let quantity else { return nil }
//
//        switch unit {
//        case .weight(let weightUnit):
//            return .init(value: (amount / quantity), unit: weightUnit)
//
//        case .serving:
//            guard let servingWeight = food.servingWeight else {
//                return nil
//            }
//
//            return .init(
//                value: (servingWeight.value * amount) / quantity,
//                unit: servingWeight.unit
//            )
//
//        case .size(let sizeUnit, let volumeUnit):
//            guard let unitWeight = sizeUnit.unitWeight(in: food) else {
//                return nil
//            }
//            return .init(
//                value: (unitWeight.value * amount) / quantity,
//                unit: unitWeight.unit
//            )
//
//            //TODO: What do we do about the volumeUnit
//        default:
//            return nil
//        }
//    }
//}

//extension FoodSize {
//    /**
//     Returns the quantity representing how much 1 of this size weights, if applicable. Drills down to the base size if necessary.
//     */
//    func unitWeight(in food: FoodEntity) -> WeightQuantity? {
//        /// Protect against zero-divison error
//        guard quantity > 0 else { return nil }
//        let unitValue = (value.value / quantity)
//
//        switch value.unitType {
//        case .weight:
//            guard let weightUnit = value.weightUnit else { return nil }
//            return WeightQuantity(value: unitValue, unit: weightUnit)
//
//        case .volume:
//            guard let volumeUnit = value.volumeUnit else { return nil }
//            guard let density = food.density else { return nil }
//            let volume = VolumeQuantity(value: unitValue, unit: volumeUnit)
//            return density.convert(volume: volume)
//
//        case .size:
//            guard let sizeId = value.sizeID,
//                  let size = food.size(for: sizeId),
//                  let unitWeightOfSize = size.unitWeight(in: food)
//            else { return nil }
//            return .init(value: unitValue * unitWeightOfSize.value, unit: unitWeightOfSize.unit)
//
//        default:
//            return nil
//        }
//    }
//
//    /**
//     Returns the volume representing 1 of this size, if applicable. Drills down to the base size if necessary.
//     */
//    func unitVolume(in food: FoodEntity) -> VolumeQuantity? {
//        /// Protect against zero-divison error
//        guard quantity > 0 else { return nil }
//        let unitValue = (value.value / quantity)
//
//        switch value.unitType {
//        case .weight:
//            guard let weightUnit = value.weightUnit else { return nil }
//            guard let density = food.density else { return nil }
//            let weight = WeightQuantity(unitValue, weightUnit)
//            return density.convert(weight: weight)
//
//        case .volume:
//            guard let volumeUnit = value.volumeUnit else { return nil }
//            return VolumeQuantity(unitValue, volumeUnit)
//
//        case .size:
//            guard let sizeId = value.sizeID,
//                  let size = food.size(for: sizeId),
//                  let unitVolumeOfSize = size.unitVolume(in: food)
//            else { return nil }
//            return .init(unitValue * unitVolumeOfSize.value, unitVolumeOfSize.unit)
//
//        default:
//            return nil
//        }
//    }
//}

// ✅ Tests Passing
extension FoodQuantity {
    
    // ✅ Tests Passing
    func convertWeight(_ weight: WeightQuantity, toUnit: Unit) -> Double? {
        switch toUnit {
            
        case .weight(let weightUnit):
            // ✅ Tests Passing
            return weight.convert(to: weightUnit)
            
        case .volume(let volumeUnit):
            // ✅ Tests Passing
            /// Get explicit unit and density
            guard let density = food.density else { return nil }
            /// Weight → Volume
            let volume = density.convert(weight: weight)
            /// Volume → VolumeUnit
            return volume.convert(to: volumeUnit)
            
        case .size(let size, let volumeUnit):
            // ✅ Tests Passing
            guard let unitWeight = size.unitWeight(in: food) else { return nil }
            let converted = unitWeight.convert(to: weight.unit)
            guard converted > 0 else { return nil }
            let weight = weight.value / converted
            return weight * size.volumePrefixScale(for: volumeUnit)
            
        case .serving:
            // ✅ Tests Passing
            guard let servingWeight = food.servingWeight else { return nil }
            let converted = servingWeight.convert(to: weight.unit)
            guard converted > 0 else { return nil }
            return value / converted
        }
    }
}

//MARK: - Replacements

extension FoodQuantity.Size {
    //⚠️ TODO: *** Look into the following, adding tests to try and capture them**
    /// [ ] why we're not passing in the volumeUnit
    
    /// Returns how many of the provided size are in 1 size of the size this is called upon.
    func quantityPerSize(of size: FoodQuantity.Size, in food: Food) -> Double? {
        
        /// If we're in the size we're querying, return 1
        guard size.id != self.id else {
            return 1
        }
        
        guard unitValue > 0 else {
            return nil
        }
        
        guard let sizeUnit = self.unit.size else {
            if size.unit.size != nil {
                /// Check the flipped size
                guard let flippedSize = size.quantityPerSize(of: self, in: food) else { return nil }
                return 1 / flippedSize
            } else {
                
                switch size.unit {
                    
                case .weight:
                    /// Get the unit weights of both sizes
                    guard let targetUnitWeight = size.unitWeight(in: food) else { return nil }
                    guard let ourUnitWeight = self.unitWeight(in: food) else { return nil }
                    
                    /// Convert the destination unit weight to match ours
                    let converted = targetUnitWeight.convert(to: ourUnitWeight.unit)
                    
                    guard converted > 0 else { return nil }
                    return ourUnitWeight.value / converted
                    
                case .volume:
                    /// Get the unit volumes of both sizes
                    guard let targetUnitVolume = size.unitVolume(in: food) else { return nil }
                    guard let ourUnitVolume = self.unitVolume(in: food) else { return nil }
                    
                    /// Convert the destination unit volume to match ours
                    let converted = targetUnitVolume.convert(to: ourUnitVolume.unit)
                    
                    guard converted > 0 else { return nil }
                    return ourUnitVolume.value / converted
                    
                case .serving:
                    /// Since the provided size wouldn't be described in `serving`, we simply flip the sizes and call this equation again, and then return the inverse of what's calculated.
                    guard let flipped = size.quantityPerSize(of: self, in: food),
                          flipped > 0
                    else { return nil }
                    
                    return 1/flipped
                    
                default:
                    return nil
                }
            }
        }
        if sizeUnit == size {
            let scale = self.unit
                .sizeVolumePrefixExplicitUnit?
                .scale(against: size.volumeUnit) ?? 1
            //            if flippedSize {
            //                return 1 / unitValue / scale
            //            } else {
            return unitValue * scale
            //            }
        } else {
            /// Recursively keep drilling down till we hit the size unit
            guard let unitSizeValue = sizeUnit.quantityPerSize(of: size, in: food) else { return nil }
            return unitSizeValue * unitValue
        }
    }
    
    
    /// Returns the unit weight of this size (ie what 1 of it weighs), if applicable. Drills down to the base size if necessary.
    func unitWeight(in food: Food) -> WeightQuantity? {
        /// Protect against zero-divison error
        guard quantity > 0 else { return nil }
        
        switch unit {
        case .weight(let weightUnit):
            return .init(value: (value / quantity), unit: weightUnit)
            
        case .volume(let volumeUnit):
            guard let density = food.density else { return nil }
            let volume = VolumeQuantity(value: (value / quantity), unit: volumeUnit)
            return density.convert(volume: volume)
            
        case .serving:
            guard let servingWeight = food.servingWeight else { return nil }
            return WeightQuantity((servingWeight.value * value) / quantity, servingWeight.unit)
            
        case .size(let sizeUnit, _):
            guard let unitWeight = sizeUnit.unitWeight(in: food) else { return nil }
            return WeightQuantity((unitWeight.value * value) / quantity, unitWeight.unit)
            
            //TODO: What do we do about the volumeUnit
        }
    }
    
    /// Returns the unit volume of this size (ie what 1 of it weighs), if applicable. Drills down to the base size if necessary.
    func unitVolume(in food: Food) -> VolumeQuantity? {
        /// Protect against zero-divison error
        guard quantity > 0 else { return nil }
        
        switch unit {
        case .weight(let weightUnit):
            guard let density = food.density else { return nil }
            let weight = WeightQuantity((value / quantity), weightUnit)
            return density.convert(weight: weight)
            
        case .volume(let volumeUnit):
            return .init((value / quantity), volumeUnit)
            
        case .serving:
            guard let servingVolume = food.servingVolume else { return nil }
            return VolumeQuantity((servingVolume.value * value) / quantity, servingVolume.unit)
            
        case .size(let sizeUnit, _):
            guard let unitVolume = sizeUnit.unitVolume(in: food) else { return nil }
            return VolumeQuantity((unitVolume.value * value) / quantity, unitVolume.unit)
            
            //TODO: What do we do about the volumeUnit
        }
    }
    
    //TODO: ***** TO BE REMOVED *******
    /// Returns the unit size of this size (ie what 1 of this size is in the provided size, in the specified volumeUnit). Drills down to the base size if necessary.
    func unitSizeValue(
        of size: FoodQuantity.Size,
        in volumeUnit: VolumeUnit? = nil,
        in food: Food
        
    ) -> Double? {
        
        switch size.unit {
            
        case .weight:
            /// Get the unit weights of both sizes
            guard let targetUnitWeight = size.unitWeight(in: food) else { return nil }
            guard let ourUnitWeight = self.unitWeight(in: food) else { return nil }
            
            /// Convert the destination unit weight to match ours
            let converted = targetUnitWeight.convert(to: ourUnitWeight.unit)
            
            guard converted > 0 else { return nil }
            return ourUnitWeight.value / converted
            
        case .volume:
            /// Get the unit volumes of both sizes
            guard let targetUnitVolume = size.unitVolume(in: food) else { return nil }
            guard let ourUnitVolume = self.unitVolume(in: food) else { return nil }
            
            /// Convert the destination unit volume to match ours
            let converted = targetUnitVolume.convert(to: ourUnitVolume.unit)
            
            guard converted > 0 else { return nil }
            return ourUnitVolume.value / converted
            
        case .serving:
            return nil
            
        case .size(_, _):
            return nil
            
            //TODO: What do we do about the volumeUnit
        }
    }
}

extension Food {

    var servingSizeQuantity: SizeQuantity? {
        guard let serving else { return nil }
        guard let id = serving.sizeID else { return nil }
        guard let size = quantitySize(for: id) else { return nil }
        return .init(serving.value, size, serving.sizeVolumeUnit)
    }
    
    func quantityInOneServing(of sizeId: String, with volumeUnit: VolumeUnit? = nil) -> Double? {
        guard let size = quantitySize(for: sizeId) else { return nil }
        return quantityPerServing(of: size, with: volumeUnit)
    }
    
    func quantityPerServing(of size: FoodQuantity.Size, with volumeUnit: VolumeUnit? = nil) -> Double? {
        guard let serving else { return nil }
        
        switch serving.unitType {
        case .weight:
            guard let sizeUnitWeight = size.unitWeight(in: self) else { return nil }
            guard sizeUnitWeight.value > 0 else { return nil }
            guard let servingWeight = servingWeight else { return nil }
            let converted = servingWeight.convert(to: sizeUnitWeight.unit)
            let servings = converted / sizeUnitWeight.value
            return servings

        case .volume:
            guard let sizeUnitVolume = size.unitVolume(in: self) else { return nil }
            guard sizeUnitVolume.value > 0 else { return nil }
            guard let servingVolume = servingVolume else { return nil }
            let converted = sizeUnitVolume.convert(to: servingVolume.unit)
            let servings = servingVolume.value / converted
            return servings

        case .size:
            guard let servingSizeQuantity else { return nil }
            
            if servingSizeQuantity.size == size {
                let scale = servingSizeQuantity.volumePrefixScale(for: volumeUnit)
                return servingSizeQuantity.value * scale
            } else {
                
                /// This is how many of the serving size 1 of the provided size equals
                guard let quantityOfServingSizePerTargetSize = size.quantityPerSize(of: servingSizeQuantity.size, in: self) else {
//                guard let quantityOfServingSizePerTargetSize = servingSizeQuantity.size.quantityPerSize(of: size, in: self) else {
                    return nil
                }
                
                /// We get this value by recursively keep drilling down till we hit the serving size or a raw measurement
                guard let quantityOfServingSizePerServing = quantityPerServing(
                    of: servingSizeQuantity.size,
                    with: volumeUnit)
//                    with: servingSizeQuantity.volumeUnit)
                else {
                    return nil
                }
                
//                let servings: Double
                
                guard quantityOfServingSizePerTargetSize > 0 else { return nil }
                let quantityPerServing = quantityOfServingSizePerServing / quantityOfServingSizePerTargetSize
                
//                guard quantityPerServingOfServingSize > 0 else { return nil }
//                servings = quantityOfServingSizePerTargetSize / quantityPerServingOfServingSize

//                if size.isParent(of: servingSizeQuantity.size) {
//                    servings = unitServings * unitSizeValue
//                } else {
////                    guard unitServings > 0 else { return nil }
////                    servings = unitSizeValue / unitServings
//                    guard unitSizeValue > 0 else { return nil }
//                    servings = unitServings / unitSizeValue
//                }
                
                let scale = 1.0 / servingSizeQuantity.volumePrefixScale
                return quantityPerServing * scale
            }
            
        default:
            return nil
        }
        
        /// convert servings to the sepcified size, volumeUnit
        // for that we'll need to get the

//        guard let servingValue = food.serving?.value else { return nil }
//
////            if size.unit.unitType == .size {
//            guard let servingUnitQuantity = food.servingSizeQuantity(
//                of: size, volumeUnit: volumeUnit)
//            else { return nil }
//
//            let numberOfSizeInEachServing = servingValue / servingUnitQuantity
//            converted = numberOfSizeInEachServing
//            } else {
//                converted = servingValue
//            }
        
    }
}

extension Food {
    //TODO: ****** TO BE REMOVED *********
    /// Returns the quantity of the provided size that 1 serving equates to
    func servingSizeQuantity(of size: FoodQuantity.Size, volumeUnit: VolumeUnit? = nil) -> Double? {
        
        guard let serving else { return nil }
        switch serving.unitType {
        case .weight:
            guard let servingWeight, let sizeUnitWeight = size.unitWeight(in: self) else { return nil }
//            let converted = servingWeight.convert(to: sizeUnitWeight.unit)
            let x = servingWeight.value / sizeUnitWeight.value
            return x
        case .volume:
            return serving.value
        case .size:
            /// Now see if this size is the serving size (and if so we stop here), otherwise keep drilling down
            if let servingSizeId = serving.sizeID {
                guard let servingSize = self.quantitySize(for: servingSizeId) else {
                    return nil
                }
                if size == servingSize {
                    let value = serving.value * size.unitValue
                    return value
                }
            }

            switch size.unit {
            case .weight(_):
                return nil
            case .volume(_):
                return nil
            case .serving:
                /// we will stop here and return it
                return nil
            case .size(let sizeUnit, let volumeUnit):
                
                /// Now see if this size is the serving size (and if so we stop here), otherwise keep drilling down
                if let servingSizeId = serving.sizeID {
                    guard let servingSize = self.quantitySize(for: servingSizeId) else {
                        return nil
                    }
                    if sizeUnit == servingSize {
                        let value = serving.value * size.unitValue
                        return value
                    }
                }
                
                guard let quantity = servingSizeQuantity(of: sizeUnit, volumeUnit: volumeUnit) else {
                    return nil
                }
                return quantity * size.unitValue
            }
        case .serving:
            /// We should never reach here, as a serving of a serving is not possible
            return nil
        }
    }
}

extension Food {
    
    //TODO: Quarantined *** TO BE REMOVED ***
    /// We can't use this as converting it to a `FormUnit` loses the explicit volume units
    var servingUnit: FormUnit? {
        guard let serving else { return nil }
        return FormUnit(foodValue: serving, in: self)
    }
    
    func size(for id: String) -> FoodSize? {
        sizes.first(where: { $0.id == id })
    }

    func quantitySize(for id: String) -> FoodQuantity.Size? {
        guard let size = size(for: id) else { return nil }
        return FoodQuantity.Size(foodSize: size, in: self)
    }

    var servingWeight: WeightQuantity? {
        
        guard let serving else { return nil }
        
        switch serving.unitType {
        case .weight:
            guard let weightUnit = serving.weightUnit else { return nil }
            return .init(value: serving.value, unit: weightUnit)
        case .volume:
            /// If the serving is expressed as a volume, *and* we have a density...
            guard let volumeUnit = serving.volumeUnit,
                  let density else {
                return nil
            }
            
            let volume = VolumeQuantity(value: serving.value, unit: volumeUnit)
            return density.convert(volume: volume)

        case .size:
            
            guard let sizeId = serving.sizeID,
//                  let size = size(for: sizeId),
                  let size = quantitySize(for: sizeId),
                  let unitWeightOfSize = size.unitWeight(in: self)
            else {
                return nil
            }
            
            return .init(
                value: unitWeightOfSize.value * serving.value,
                unit: unitWeightOfSize.unit
            )
            
        case .serving:
            /// We should never reach here, as a serving of a serving is not possible
            return nil
        }
    }
    
    var servingVolume: VolumeQuantity? {
        
        guard let serving else { return nil }
        
        switch serving.unitType {
        case .weight:
            /// If the serving is expressed as a volume, *and* we have a density...
            guard let weightUnit = serving.weightUnit,
                  let density
            else { return nil }
            
            let weight = WeightQuantity(serving.value, weightUnit)
            return density.convert(weight: weight)

        case .volume:
            guard let volumeUnit = serving.volumeUnit else { return nil }
            return .init(serving.value, volumeUnit)

        case .size:
            guard let sizeId = serving.sizeID,
                  let size = quantitySize(for: sizeId),
                  let unitVolumeOfSize = size.unitVolume(in: self)
            else {
                return nil
            }

            return .init(
                value: unitVolumeOfSize.value * serving.value,
                unit: unitVolumeOfSize.unit
            )
            
        case .serving:
            /// We should never reach here, as a serving of a serving is not possible
            return nil
        }
    }
}
