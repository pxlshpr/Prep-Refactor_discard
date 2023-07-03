import Foundation
import FoodDataTypes
import FoodLabelScanner

extension ScanResult {
    
    func amount(for column: Int) -> FormValue? {
        switch headerType(for: column) {
        case .perServing:
            return FormValue(1, .serving)
        default:
            return headerValue(for: column)
        }
    }
    
    func serving(for column: Int) -> FormValue? {
        /// If we have a header type for the column and it's not `.perServing`, return `nil` immediately
        if let headerType = headerType(for: column) {
            guard headerType == .perServing else {
                return nil
            }
        }
        
        if let servingAmount {
            return FormValue(servingAmount, servingFormUnit)
        } else {
            return headerValue(for: column)
        }
    }
}

//MARK: - Density

extension ScanResult {
    var density: FoodDensity? {
        /// Check if we have an equivalent serving size
        /// Otherwise check if we have a header equivalent size for any of the headers
        equivalentSizeDensity ?? headerEquivalentSizeDensity
    }
    
    var headerEquivalentSizeDensity: FoodDensity? {
        guard let headerEquivalentSize,
              let headerEquivalentSizeUnit = headerEquivalentSize.unit,
              let headerServingUnit,
              let headerServingAmount
        else {
            return nil
        }
        
        return densityFrom(
            (headerEquivalentSize.amount, headerEquivalentSizeUnit),
            (headerServingAmount, headerServingUnit)
        )
    }
    
    func densityFrom(
        _ value1: (amount: Double, unit: FoodLabelUnit),
        _ value2: (amount: Double, unit: FoodLabelUnit)
    ) -> FoodDensity?
    {
        if let weightUnit = value1.unit.formUnit?.weightUnit,
           let volumeUnit = value2.unit.formUnit?.volumeUnit
        {
            return FoodDensity(
                weightAmount: value1.amount,
                weightUnit: weightUnit,
                volumeAmount: value2.amount,
                volumeUnit: volumeUnit
            )

        } else if
            let weightUnit = value2.unit.formUnit?.weightUnit,
            let volumeUnit = value1.unit.formUnit?.volumeUnit
        {
            return FoodDensity(
                weightAmount: value2.amount,
                weightUnit: weightUnit,
                volumeAmount: value1.amount,
                volumeUnit: volumeUnit
            )

        } else {
            return nil
        }
    }
    
    var equivalentSizeDensity: FoodDensity? {
        guard let equivalentSize,
              let equivalentSizeUnit = equivalentSize.unit,
              let servingUnit,
              let servingAmount
        else {
            return nil
        }
        
        return densityFrom(
            (equivalentSize.amount, equivalentSizeUnit),
            (servingAmount, servingUnit)
        )
    }

}

//MARK: - Sizes

extension ScanResult {
    
    /**
     Returns all the extracted sizes.
     
     The column is needed in case the column picked has a `HeaderType` of either `.per100g` or `.per100ml`,
     in which case—an additional size with the name "serving" will be returned with the amount of the
     */
    func allSizes(at column: Int) -> [FormSize] {
        var sizes: [FormSize] =
        [
            servingUnitSize,
            equivalentUnitSize,
            perContainerSize,
            headerServingSize,
            headerEquivalentUnitSize
        ]
        .compactMap { $0 }
        
        let eitherColumnIsPer100 = headerType(for: column) == .per100g || headerType(for: column) == .per100ml
        if eitherColumnIsPer100, let servingSize {
            sizes.append(servingSize)
        }
        return sizes
    }
    
    var servingSize: FormSize? {
        guard let servingAmount else { return nil }
        return FormSize(
            name: "serving",
            amount: servingAmount,
            unit: servingFormUnit
        )
    }

    var headerServingSize: FormSize? {
        guard let headerServingUnitName,
              let headerServingAmount, headerServingAmount > 0
        else {
            return nil
        }
        
        let sizeAmount: Double
        let sizeUnit: FormUnit
        if let headerEquivalentSize {
            if let headerEquivalentSizeUnitSize {
                /// Foods that have a size for both the serving unit and equivalence
                ///     e.g. 1 pack (5 pieces)
                guard headerEquivalentSize.amount > 0 else {
                    return nil
                }
//                sizeAmount = 1.0/amount/equivalentSize.amount
                sizeAmount = headerEquivalentSize.amount/headerServingAmount
                sizeUnit = .size(headerEquivalentSizeUnitSize, nil)
            } else {
                sizeAmount = headerEquivalentSize.amount/headerServingAmount
                sizeUnit = headerEquivalentSize.unit?.formUnit ?? .weight(.g)
            }
        } else {
            sizeAmount = 1.0/headerServingAmount
            sizeUnit = .serving
        }
        return FormSize(
            name: headerServingUnitName,
            amount: sizeAmount,
            unit: sizeUnit
        )
    }
    
    var headerEquivalentUnitSize: FormSize? {
        guard let headerServingAmount, headerServingAmount > 0,
              let headerEquivalentSize, headerEquivalentSize.amount > 0,
              let unitName = headerEquivalentSize.unitName
        else {
            return nil
        }
        
        return FormSize(
            name: unitName,
//            amount: 1.0/amount/equivalentSize.amount,
            amount: headerServingAmount/headerEquivalentSize.amount,
            unit: headerServingFormUnit
        )
    }
    
    var perContainerSize: FormSize? {
        guard let perContainer = serving?.perContainer else {
            return nil
        }
        return FormSize(
            quantity: 1,
            name: perContainer.name ?? "container",
            amount: perContainer.amount,
            unit: .serving
        )
    }
    
    var equivalentUnitSize: FormSize? {
        guard let servingAmount, servingAmount > 0,
              let equivalentSize, equivalentSize.amount > 0,
              let unitNameText = equivalentSize.unitNameText
        else {
            return nil
        }
        
        return FormSize(
            name: unitNameText.string,
//            amount: 1.0/amount/equivalentSize.amount,
            amount: servingAmount/equivalentSize.amount,
            unit: servingFormUnit
        )
    }
}

//MARK: - Barcodes

extension ScanResult {
    var barcodeStrings: [String] {
        barcodes.map { $0.string }
    }
}

//MARK: - Header Helpers

extension ScanResult {
    
    func headerValue(for column: Int) -> FormValue? {
        guard let amount = headerAmount(for: column) else { return nil }
        return FormValue(amount, headerFormUnit(for: column))
    }
    
    func headerAmount(for column: Int) -> Double? {
        guard let headerType = headerType(for: column) else {
            return nil
        }
        switch headerType {
        case .per100g, .per100ml:
            return 100
        case .perServing:
            return headerServingAmount
        }
    }
    
    func headerFormUnit(for column: Int) -> FormUnit {
        guard let headerType = headerType(for: column) else {
            return .serving
        }
        
        switch headerType {
        case .per100g:
            return .weight(.g)
        case .per100ml:
            return .volume(.mL)
        case .perServing:
            return headerServingFormUnit
        }
    }
    
    var headerServingFormUnit: FormUnit {
        if let headerServingUnitName {
            let size = FormSize(
                name: headerServingUnitName,
                amount: headerServingUnitAmount,
                unit: headerServingUnitSizeUnit
            )
            return .size(size, nil)
        } else {
            return headerServingUnit?.formUnit ?? .weight(.g)
        }
    }
}

//MARK: - Helpers

extension ScanResult {

    func headerType(for column: Int) -> HeaderType? {
        column == 1 ? headers?.header1Type : headers?.header2Type
    }
    
    var headerServingAmount: Double? {
        headers?.serving?.amount
    }
    
    var headerServingUnitName: String? {
        headers?.serving?.unitName
    }
    
    var headerServingUnitAmount: Double {
        if let headerEquivalentSize {
            return headerEquivalentSize.amount
        } else {
            return headers?.serving?.amount ?? 1
        }
    }
    
    var headerServingUnitSizeUnit: FormUnit {
        headerEquivalentSizeFormUnit ?? .serving
    }
    
    var headerServingUnit: FoodLabelUnit? {
        headers?.serving?.unit
    }

    var headerEquivalentSize: HeaderText.Serving.EquivalentSize? {
        headers?.serving?.equivalentSize
    }
    var servingFormUnit: FormUnit {
        if let servingUnitSize {
            return .size(servingUnitSize, nil)
        } else {
            return servingUnit?.formUnit ?? .weight(.g)
        }
    }

    var servingUnitSize: FormSize? {
        guard let servingUnitNameText,
              let servingAmount, servingAmount > 0
        else {
            return nil
        }
        
        let sizeAmount: Double
        let sizeUnit: FormUnit
        if let equivalentSize {
            if let equivalentSizeUnitSize {
                /// Foods that have a size for both the serving unit and equivalence
                ///     e.g. 1 pack (5 pieces)
                guard equivalentSize.amount > 0 else {
                    return nil
                }
//                sizeAmount = 1.0/amount/equivalentSize.amount
                sizeAmount = equivalentSize.amount/servingAmount
                sizeUnit = .size(equivalentSizeUnitSize, nil)
            } else {
                sizeAmount = equivalentSize.amount / servingAmount
                sizeUnit = equivalentSize.unit?.formUnit ?? .weight(.g)
            }
        } else {
            sizeAmount = 1.0/servingAmount
            sizeUnit = .serving
        }
        return FormSize(
            name: servingUnitNameText.string,
            amount: sizeAmount,
            unit: sizeUnit
        )
    }
    
    var servingUnitAmount: Double {
        if let equivalentSize {
            return equivalentSize.amount
        } else {
            return servingAmount ?? 1
        }
    }
    
    var servingUnitSizeUnit: FormUnit {
        equivalentSizeFormUnit ?? .serving
    }
    
    var equivalentSizeFormUnit: FormUnit? {
        if let equivalentSizeUnitSize {
            return .size(equivalentSizeUnitSize, nil)
        } else {
            return equivalentSize?.unit?.formUnit
        }
    }
    
    var headerEquivalentSizeFormUnit: FormUnit? {
        if let headerEquivalentSizeUnitSize {
            return .size(headerEquivalentSizeUnitSize, nil)
        } else {
            return headerEquivalentSize?.unit?.formUnit ?? .weight(.g)
        }
    }
    
    var headerEquivalentSizeUnitSize: FormSize? {
        guard let headerEquivalentSize, headerEquivalentSize.amount > 0,
              let headerServingAmount, headerServingAmount > 0
        else {
            return nil
        }
        
        if let unitName = headerEquivalentSize.unitName {
            return FormSize(
                name: unitName,
                amount: 1.0/headerServingAmount/headerEquivalentSize.amount,
                unit: .serving)
        } else {
            return nil
        }
    }
    
    var equivalentSizeUnitSize: FormSize? {
        guard let equivalentSize, equivalentSize.amount > 0,
              let servingAmount, servingAmount > 0
        else {
            return nil
        }
        
        if let unitNameText = equivalentSize.unitNameText {
            return FormSize(
                name: unitNameText.string,
                amount: 1.0/servingAmount/equivalentSize.amount,
                unit: .serving)
        } else {
            return nil
        }
    }
    
    var servingAmount: Double? {
        serving?.amount
    }
    
    var servingUnitNameText: StringText? {
        serving?.unitNameText
    }
    
    var servingUnit: FoodLabelUnit? {
        serving?.unit
    }
    var equivalentSize: ScanResult.Serving.EquivalentSize? {
        serving?.equivalentSize
    }
}


extension ScanResult.Headers {
    var serving: HeaderText.Serving? {
        if header1Type == .perServing {
            return headerText1?.serving
        } else if header2Type == .perServing {
            return headerText2?.serving
        } else {
            return nil
        }
    }
}
