import SwiftUI
import UIKit
import Observation
import PhotosUI

import FoodDataTypes
import FoodLabelScanner

@Observable class FoodModel {

    var foodBeingEdited: Food? = nil
    
    var foodType: FoodType = .food

    var emoji: String = ""
    var name: String = ""
    var detail: String = ""
    var brand: String = ""
    
    var amountValue: Double = DefaultAmountValue.amount
    var amountUnit: FormUnit = DefaultAmountValue.unit
    var servingValue: Double? = nil
    var servingUnit: FormUnit? = nil

    var energy = NutrientValue(value: 0, energyUnit: .kcal)
    var carb = NutrientValue(macro: .carb)
    var fat = NutrientValue(macro: .fat)
    var protein = NutrientValue(macro: .protein)
    
    var micros: [NutrientValue] = []
    var microGroups: [MicroGroup: [NutrientValue]] = [:]

    var sizes: [FormSize] = []
    var newSize: FormSize = FormSize()
    var sizeBeingEdited: FormSize? = nil

    var hasDensity: Bool = false
    var weightValue: Double = DefaultDensity.weightAmount
    var weightUnit: FormUnit = .weight(DefaultDensity.weightUnit)
    var volumeValue: Double = DefaultDensity.volumeAmount
    var volumeUnit: FormUnit = .volume(DefaultDensity.volumeUnit)

    var barcode: String? = nil
    var scanResult: ScanResult? = nil
    var urlString: String = ""
    var isPublished: Bool = false

    var imageIDs: [UUID] = []

    /// Recipe and Plate related
    var foodItems: [FoodItem] = []
    
    /// Not stored
    var path: [FoodFormRoute] = []
    var images: [UIImage] = []
    var presentedImageIndex: Int = 0
    var showingImageViewer = false

    var showingCancelConfirmation = false
    var showingDeleteConfirmation = false
    var showingDensityForm = false
    var showingBarcodeScanner = false
    var showingPhotosPicker = false
    var showingCamera = false
    var showingColumnConfirmation = false
    var hasAppeared = false
    var selectedPhotos: [PhotosPickerItem] = []

    var isProcessingImage = false
    var processingStatus: String = ""
    var alertMessage: String = ""
    var isPresentingAlert: Bool = false

    var updateSmallPieChartTask: Task<Void, Error>? = nil

    var isDeleting = false
    var saveDisabled = true
    var dismissDisabled = false
    var saveDisabledTask: Task<Void, Error>? = nil

    var smallChartData: [MacroValue] = []
    var largeChartData: [MacroValue] = []

    init() {
        emoji = String.randomFoodEmoji
    }

    func reset(newFoodType: FoodType) {
        foodBeingEdited = nil
        foodType = newFoodType
        
        emoji = String.randomFoodEmoji
        name = ""
        detail = ""
        brand = ""
        
        amountValue = DefaultAmountValue.amount
        amountUnit = DefaultAmountValue.unit
        servingValue = nil
        servingUnit = nil
        
        energy = NutrientValue(value: 0, energyUnit: .kcal)
        carb = NutrientValue(macro: .carb)
        fat = NutrientValue(macro: .fat)
        protein = NutrientValue(macro: .protein)
        micros = []
        
        sizes = []
        newSize = FormSize()
        sizeBeingEdited = nil
        
        hasDensity = false
        weightValue = DefaultDensity.weightAmount
        weightUnit = .weight(DefaultDensity.weightUnit)
        volumeValue = DefaultDensity.volumeAmount
        volumeUnit = .volume(DefaultDensity.volumeUnit)
        
        barcode = nil
        scanResult = nil
        urlString = ""
        isPublished = false
        
        images = []
        imageIDs = []
        smallChartData = []
        largeChartData = []
        saveDisabled = true
        dismissDisabled = false
    }
    
    func reset(existingFood food: Food) {
        foodBeingEdited = food
        foodType = food.type
        
        emoji = food.emoji
        name = food.name
        detail = food.detail ?? ""
        brand = food.brand ?? ""
        energy = NutrientValue(value: food.energy, energyUnit: food.energyUnit)
        carb = NutrientValue(macro: .carb, value: food.carb)
        fat = NutrientValue(macro: .fat, value: food.fat)
        protein = NutrientValue(macro: .protein, value: food.protein)
        
        self.smallChartData = self.macrosChartData
        self.largeChartData = self.macrosChartData

        self.amountValue = food.amount.value
        self.amountUnit = food.amount.formUnit(for: food) ?? .weight(.g)
        self.servingValue = food.serving?.value
        self.servingUnit = food.serving?.formUnit(for: food)

        self.micros = food.micros.compactMap { NutrientValue($0) }

        
        self.sizes = food.sizes.compactMap { $0.formSize(for: food) }
        self.newSize = FormSize()
        self.sizeBeingEdited = nil
        
        if let density = food.density {
            self.hasDensity = true
            self.weightValue = density.weightAmount
            self.weightUnit = .weight(density.weightUnit)
            self.volumeValue = density.volumeAmount
            self.volumeUnit = .volume(density.volumeUnit)
        } else {
            self.hasDensity = false
            self.weightValue = DefaultDensity.weightAmount
            self.weightUnit = .weight(DefaultDensity.weightUnit)
            self.volumeValue = DefaultDensity.volumeAmount
            self.volumeUnit = .volume(DefaultDensity.volumeUnit)
        }
        
        self.barcode = food.barcodes.first
        self.scanResult = nil
        self.urlString = food.url ?? ""
        self.isPublished = food.publishStatus == .hidden ? false : true
        
        self.images = []
        self.imageIDs = food.imageIDs
        self.loadImages()
        saveDisabled = true
        dismissDisabled = false
    }
    
    func loadImages() {
        Task.detached(priority: .medium) {
            imagesLogger.debug("Loading images")
            let start = CFAbsoluteTimeGetCurrent()
            for id in self.imageIDs {
                guard let image = await ImageManager.load(id) else {
                    continue
                }
                await MainActor.run {
                    withAnimation {
                        self.images.append(image)
                    }
                }
            }
            imagesLogger.debug("Images loaded in: \(CFAbsoluteTimeGetCurrent()-start)s")
        }
    }
}

import SwiftSugar

extension FoodModel {    
    func delayedSetSaveDisabled() {
        saveDisabledTask?.cancel()
        saveDisabledTask = Task.detached(priority: .userInitiated) {
            /// sleep to let the animation complete first
            try await sleepTask(1)
            try Task.checkCancellation()
            await MainActor.run {
                self.setSaveDisabled()
            }
        }
    }

    func delayedUpdateSmallPieChart() {
        updateSmallPieChartTask?.cancel()
        updateSmallPieChartTask = Task.detached(priority: .userInitiated) {
            /// sleep to let the animation complete first
            try await sleepTask(1)
            try Task.checkCancellation()
            await MainActor.run {
                self.smallChartData = self.macrosChartData
            }
        }
    }

    var shouldShowPieChart: Bool {
        !(
            carb.value == 0
            && fat.value == 0
            && protein.value == 0
        )
    }
    
    var density: FoodDensity? {
        guard hasDensity else { return nil }
        return FoodDensity(
            weightAmount: weightValue,
            weightUnit: weightUnit.weightUnit ?? .g,
            volumeAmount: volumeValue,
            volumeUnit: volumeUnit.volumeUnit ?? .cupMetric
        )
    }
    
    var standardSizes: [FormSize] {
        sizes
            .filter { !$0.isVolumePrefixed }
            .sorted()
    }
    
    var volumePrefixedSizes: [FormSize] {
        sizes
            .filter { $0.isVolumePrefixed }
            .sorted()
    }
    
    var isWeightBased: Bool {
        amountUnit.isWeightBased || servingUnit?.isWeightBased == true
    }

    var canSaveNewSize: Bool {
        var sizesToCheck: [FormSize] = sizes
        if let sizeBeingEdited {
            sizesToCheck.removeAll(where: { $0.id == sizeBeingEdited.id })
        }
        return !sizesToCheck.contains(where: {
            $0.name.lowercased() == newSize.name.lowercased()
        })
    }
    
    var constructedMicroGroups: [MicroGroup] {
        micros
            .compactMap { $0.micro?.group }
            .removingDuplicates()
            .sorted()
    }
    
    var availableMicroGroupsToAdd: [MicroGroup] {
        MicroGroup.allCases
            .filter { !availableMicros(in: $0).isEmpty }
    }
    
    func availableMicros(in group: MicroGroup) -> [Micro] {
        group
            .micros
            .filter { micro in
                /// Get all the micros we've added in that group
                let addedMicros = self.micros
                    .filter { $0.micro?.group == group }
                    .compactMap { $0.micro }
                return !addedMicros.contains(micro)
            }
    }
    
    func add(_ micros: [Micro]) {
        self.micros.append(contentsOf: micros.map {
            NutrientValue(micro: $0, value: 0, unit: $0.defaultUnit)
        })
    }
    
    func remove(_ micros: [Micro]) {
        self.micros.removeAll(where: {
            guard let micro = $0.micro else { return false }
            return micros.contains(micro)
        })
    }
        
    func nutrientValues(for group: MicroGroup) -> [NutrientValue] {
        micros
            .filter { $0.micro?.group == group }
    }

    func nutrients(for group: MicroGroup) -> [Nutrient] {
        micros
            .filter { $0.micro?.group == group }
            .compactMap { $0.micro }
            .map { Nutrient.micro($0) }
    }

}

extension FoodModel {
    
    var isEditing: Bool {
        foodBeingEdited != nil
    }
    
//    func fillFood(_ food: Food) {
//        var food = food
//        food.emoji = emoji
//        food.name = name
//        food.detail = detail
//        food.brand = brand
//        
//        food.amount = FoodValue(amountValue, amountUnit)
//        if amountUnit == .serving {
//            food.serving = FoodValue(servingValue, servingUnit)
//        } else {
//            food.serving = nil
//        }
//        
//        food.energy = energy.value
//        food.energyUnit = energy.unit.energyUnit ?? .kcal
//        
//        food.carb = carb.value
//        food.fat = fat.value
//        food.protein = protein.value
//        food.micros = micros.compactMap { FoodNutrient($0) }
//        
//        food.sizes = sizes.map { FoodSize($0) }
//        food.density = density
//        
//        if let barcode {
//            food.barcodes = [barcode]
//        } else {
//            food.barcodes = []
//        }
//        food.url = urlString
//
//        switch food.publishStatus {
//        case .hidden, .pendingReview, .rejected, .none:
//            food.publishStatus = isPublished ? .pendingReview : .hidden
//        case .verified:
//            food.publishStatus = isPublished ? .pendingReview : .hidden
//        }
//        
//        food.imageIDs = imageIDs
//    }
    
    var updatedFood: Food? {
        guard let foodBeingEdited else { return nil }
        var food = foodBeingEdited
        food.fill(with: self)
        food.updatedAt = Date.now
        return food
    }
    
    var canBeDeleted: Bool {
        guard let foodBeingEdited,
              foodBeingEdited.dataset == nil else {
            return false
        }
        return true
    }
    
    var newFood: Food {
        var food = Food()
        food.fill(with: self)
        food.createdAt = Date.now
        food.updatedAt = Date.now
        return food
    }
    
    func setSaveDisabled() {
        guard !isDeleting else {
            saveDisabled = true
            dismissDisabled = true
            saveDisabledLogger.debug("saveDisabled set to true")
            return
        }
        
        //TODO: For both of these consider validity of food
        /// [ ] Density values cannot be 0
        /// [ ] Check any other stuff we won't allow
        saveDisabled = shouldDisableSave
        dismissDisabled = shouldDisableDismiss
        
        saveDisabledLogger.debug("saveDisabled set to \(String(describing: self.saveDisabled), privacy: .public)")
        saveDisabledLogger.debug("dismissDisabled set to \(String(describing: self.dismissDisabled), privacy: .public)")
    }
    
    func hasPendingChanges(from food: Food) -> Bool {
        let densityIsEqual = if let density = food.density {
            weightValue.roughlyMatches(density.weightAmount)
            && volumeValue.roughlyMatches(density.volumeAmount)
            && weightUnit.weightUnit == density.weightUnit
            && volumeUnit.volumeUnit == density.volumeUnit
        } else {
            !hasDensity
        }
        
        let textsAreEqual = emoji == food.emoji
        && name == food.name
        && detail == food.detail ?? ""
        && brand == food.brand ?? ""
        && barcode == food.barcodes.first
        && urlString == ""

        let servingsAreEqual = if let serving = food.serving {
            if let servingValue, let servingUnit {
                servingValue.roughlyMatches(serving.value)
                && servingUnit == serving.formUnit(for: food) ?? .weight(.g)
            } else {
                false
            }
        } else {
            servingValue == nil
            && servingUnit == nil
        }
        
        let numbersAreEqual = amountValue.roughlyMatches(food.amount.value)
//        && servingValue.roughlyMatches(food.serving?.value ?? 0)
        && energy.value.roughlyMatches(food.energy)
        && carb.value.roughlyMatches(food.carb)
        && fat.value.roughlyMatches(food.fat)
        && protein.value.roughlyMatches(food.protein)
        
        let unitsAreEqual = amountUnit == food.amount.formUnit(for: food) ?? .weight(.g)
//        && servingUnit == food.serving?.formUnit(for: food) ?? .weight(.g)
        && energy.unit == food.energyUnit.nutrientUnit
        
        let arraysAreEqual = imageIDs == food.imageIDs
        && micros.roughlyMatches(food.micros.compactMap { NutrientValue($0) })
        && sizes.roughlyMatches(food.sizes.compactMap { $0.formSize(for: food) })

        return !(
            textsAreEqual
            && numbersAreEqual
            && unitsAreEqual
            && servingsAreEqual
            && densityIsEqual
            && arraysAreEqual
            && isPublished == food.isPublished
        )
    }
    
    var isValid: Bool {
        /// Required fields
        guard name != "", emoji != "" else {
            return false
        }
        
        /// **Validation Logic**

        /// Amount has to be greater than 0
        guard amountValue > 0 else {
            return false
        }
        
        /// If we've set the publish status, ensure we have at least 1 image or a link
        if isPublished {
            guard (!images.isEmpty || !urlString.isEmpty) else {
                return false
            }
        }
        
        return true
    }
    
    var shouldDisableSave: Bool {
        if let food = foodBeingEdited {
            /// Can be saved if we have pending changes
            !hasPendingChanges(from: food)
        } else {
            !isValid
        }
    }
    
    var shouldDisableDismiss: Bool {
        if let food = foodBeingEdited {
            /// Can be saved if we have pending changes
            hasPendingChanges(from: food)
        } else {
            hasEnteredData
        }
    }
    
    var hasEnteredData: Bool {
        !(
            emoji == ""
            && name == ""
            && detail == ""
            && brand == ""
            && amountValue == DefaultAmountValue.amount
            && amountUnit == DefaultAmountValue.unit
            && servingValue == nil
            && servingUnit == nil
            && energy == NutrientValue(value: 0, energyUnit: .kcal)
            && carb == NutrientValue(macro: .carb)
            && fat == NutrientValue(macro: .fat)
            && protein == NutrientValue(macro: .protein)
            && micros == []
            && sizes == []
            && newSize == FormSize()
            && hasDensity == false
            && weightValue == DefaultDensity.weightAmount
            && weightUnit == .weight(DefaultDensity.weightUnit)
            && volumeValue == DefaultDensity.volumeAmount
            && volumeUnit == .volume(DefaultDensity.volumeUnit)
            && barcode == nil
            && scanResult == nil
            && urlString == ""
            && isPublished == false
            && imageIDs == []
        )
    }

}

extension FoodModel {
    
    func prepareSizeForRemoval(_ sizeToRemove: FormSize, at index: Int) -> [FormSize] {
        var cascades: [FormSize] = []
        /// Delete any sizes that are using this size as a unit
        for i in sizes.indices {
            let size = sizes[i]
            guard size.unit.sizeID == sizeToRemove.id else {
                continue
            }
            cascades.append(size)
            cascades = cascades + prepareSizeForRemoval(size, at: i)
        }
        if amountUnit.sizeID == sizeToRemove.id {
            amountUnit = sizeToRemove.replacementUnit
        }
        if servingUnit?.sizeID == sizeToRemove.id {
            servingUnit = sizeToRemove.replacementUnit
        }
        return cascades
    }
    
    func setAmountUnit(_ newUnit: FormUnit) {
        /// If we're removing the concept of a 'serving'—delete any sizes that used serving as a unit (and cascade it to any sizes that used that size, etc.)
        if amountUnit == .serving, newUnit != .serving {
            let indexes = sizes
                .filter { $0.unit == .serving }
                .compactMap { size in
                    sizes.firstIndex(where: { $0.id == size.id })
                }
            let offsets = IndexSet(indexes)
            removeSizes(at: offsets)
            
            /// If the unit we're setting to happens to be serving-based (it can't .serving, since we're checking for that in the enclosing if-statement)—then set the amount unit to be `.weight(.g)` instead since it would be deleted. We're not using the replacement unit here as it would be `.serving`, which would confuse the user as the serving-based sizes would get deleted but the serving size gets re-instated automatically.
            if newUnit.isServingBased {
                self.amountUnit = .weight(.g)
                return
            }
        }
        
        /// If we're moving from the initial amount to `serving`, set the amount to `1` as it's the most likely value we'd be using.
        if amountUnit == DefaultAmountValue.unit,
           amountValue == DefaultAmountValue.amount,
           newUnit == .serving
        {
            amountValue = 1
        }
        
        self.amountUnit = newUnit
    }
    func removeSizes(at offsets: IndexSet) {
        var cascades: [FormSize] = []
        for offset in offsets {
            cascades = cascades + prepareSizeForRemoval(sizes[offset], at: offset)
        }
        withAnimation(.snappy) {
            sizes.remove(atOffsets: offsets)
            sizes.removeAll(where: { size in
                cascades.contains(where: { $0.id == size.id })
            })
        }
    }

    func updateSize(_ oldSize: FormSize, to newSize: FormSize, index: Int) {
        for i in sizes.indices {
            let size = sizes[i]
            guard size.unit.sizeID == oldSize.id else {
                continue
            }
            sizes[i].unit = .size(newSize, size.unit.sizeVolumeUnit)
        }

        if amountUnit.sizeID == oldSize.id {
            amountUnit = .size(newSize, amountUnit.sizeVolumeUnit)
        }
        if let servingUnit, servingUnit.sizeID == oldSize.id {
            self.servingUnit = .size(newSize, servingUnit.sizeVolumeUnit)
        }
        sizes.remove(at: index)
        sizes.insert(newSize, at: index)
    }
    
    func saveSize() {
        if let sizeBeingEdited,
           let index = sizes.firstIndex(where: { $0.id == sizeBeingEdited.id })
        {
            updateSize(sizeBeingEdited, to: newSize, index: index)
        } else {
            sizes.append(newSize)
        }
        newSize = FormSize()
        sizeBeingEdited = nil
        setSaveDisabled()
    }
    
    func addServingBasedSize(_ name: String) {
        let newSize = FormSize(
            quantity: 1,
            volumeUnit: nil,
            name: name,
            amount: 1,
            unit: .serving
        )
        sizes.append(newSize)

        if amountUnit == DefaultAmountValue.unit,
           amountValue == DefaultAmountValue.amount
        {
            amountValue = 1
        }
        amountUnit = .serving
        if servingValue == nil {
            servingValue = 1
        }
        servingUnit = .size(newSize, nil)
        setSaveDisabled()
    }
}

extension FoodModel {
    
    func fillInAmount(_ formValue: FormValue) {
        self.amountValue = formValue.amount
        self.amountUnit = formValue.unit
    }

    func fillInServing(_ formValue: FormValue) {
        self.servingValue = formValue.amount
        self.servingUnit = formValue.unit
    }
    
    func fillInSizes(_ sizes: [FormSize]) {
        for size in sizes {
            guard !self.sizes.contains(where: { $0.id == size.id }) else { continue }
            self.sizes.append(size)
        }
    }
    
    func fillIn(_ density: FoodDensity) {
        self.hasDensity = true
        self.weightValue = density.weightAmount
        self.weightUnit = .weight(density.weightUnit)
        self.volumeValue = density.volumeAmount
        self.volumeUnit = .volume(density.volumeUnit)
    }

    func fillIn(_ nutrients: [ExtractedNutrient]) {
        for nutrient in nutrients {
            guard let nutrientValue = NutrientValue(extractedNutrient: nutrient) else {
                continue
            }
            fillIn(nutrientValue)
        }
    }
    
    func fillInBarcodes(_ barcodes: [String]) {
        for scannedBarcode in barcodes {
            if let barcode {
                guard barcode != scannedBarcode else {
                    continue
                }
            }
            self.barcode = scannedBarcode
        }
    }
    
    func fillIn(_ nutrientValue: NutrientValue) {
        switch nutrientValue.nutrient {
        case .energy:
            self.energy = nutrientValue
        case .macro(let macro):
            switch macro {
            case .carb:
                self.carb = nutrientValue
            case .fat:
                self.fat = nutrientValue
            case .protein:
                self.protein = nutrientValue
            }
        case .micro:
            self.micros.removeAll(where: { $0.micro == nutrientValue.nutrient.micro })
            self.micros.append(nutrientValue)
        }
    }
    
    func addImage(_ image: UIImage) {
        let id = UUID()
        images.append(image)
        imageIDs.append(id)
        
        Task.detached(priority: .utility) {
            ImageManager.save(image: image, id: id)
        }
        
        setSaveDisabled()
    }
    
    func removeImages(at offsets: IndexSet) {
        for offset in offsets {
            let id = imageIDs[offset]
            Task.detached(priority: .utility) {
                ImageManager.delete(id)
            }
        }
        
        images.remove(atOffsets: offsets)
        imageIDs.remove(atOffsets: offsets)
        
        setSaveDisabled()
    }
    
    func discardNewImages() {
        let imageIDsToKeep = foodBeingEdited?.imageIDs ?? []
        for imageID in self.imageIDs {
            guard !imageIDsToKeep.contains(imageID) else {
                continue
            }
            ImageManager.delete(imageID)
        }
    }
}

import OSLog
let imagesLogger = Logger(subsystem: "FoodForm", category: "Images")

import Charts

extension FoodModel {
    
    var macrosChartData: [MacroValue] {
        [
            MacroValue(macro: .carb, value: carb.value),
            MacroValue(macro: .fat, value: fat.value),
            MacroValue(macro: .protein, value: protein.value)
        ]
    }

    
    var servingFoodValue: FoodValue? {
        guard let servingValue, let servingUnit else {
            return nil
        }
        return FoodValue(servingValue, servingUnit)
    }
    
    var hasServing: Bool {
        servingFoodValue != nil
    }
}

extension Food {
    
    mutating func fill(with model: FoodModel) {
        emoji = model.emoji
        name = model.name
        detail = model.detail
        brand = model.brand
        
        amount = FoodValue(model.amountValue, model.amountUnit)
        if model.amountUnit == .serving, let servingFoodValue = model.servingFoodValue {
            serving = servingFoodValue
        } else {
            serving = nil
        }
        
        energy = model.energy.value
        energyUnit = model.energy.unit.energyUnit ?? .kcal
        
        carb = model.carb.value
        fat = model.fat.value
        protein = model.protein.value
        micros = model.micros.compactMap { FoodNutrient($0) }
        
        sizes = model.sizes.map { FoodSize($0) }
        density = model.density
        
        if let barcode = model.barcode {
            barcodes = [barcode]
        } else {
            barcodes = []
        }
        url = model.urlString

        switch publishStatus {
        case .hidden, .pendingReview, .rejected, .none:
            publishStatus = model.isPublished ? .pendingReview : .hidden
        case .verified:
            publishStatus = model.isPublished ? .pendingReview : .hidden
        }
        
        imageIDs = model.imageIDs
    }
}
