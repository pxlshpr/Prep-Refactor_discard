import SwiftUI
import OSLog
import Charts

import FoodDataTypes
import SwiftHaptics

private let logger = Logger(subsystem: "ItemForm", category: "")

let DefaultAmount: Double = 100
let DefaultUnit: FormUnit = .weight(.g)

struct ItemForm: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
//    var showingItem = false
    @State var amount: Double
    @State var unit: FormUnit
    @State var meal: Meal? = nil
//    var foodItem: FoodItem? = nil

    @State var food: Food? = nil
    @State var foodItem: FoodItem? = nil

    @Binding var isPresented: Bool
    
    public init(
        isPresented: Binding<Bool>,
        meal: Meal?,
        food: Food
    ) {
        _isPresented = isPresented
        _meal = State(initialValue: meal)
        _food = State(initialValue: food)
        

        let amount: Double?
        let unit: FormUnit?
        /// Either set the latest used quantity or the default one
        if let lastAmount = food.lastAmount {
            amount = lastAmount.value
            unit = lastAmount.formUnit(for: food)
        } else {
            let quantity = food.defaultQuantity
            amount = quantity?.value
            unit = quantity?.unit.formUnit
        }
        _amount = State(initialValue: amount ?? DefaultAmount)
        _unit = State(initialValue: unit ?? DefaultUnit)
    }

    var body: some View {
        NavigationStack {
            form
                .navigationTitle("New Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
    }
    
    var foodValue: FoodValue {
        FoodValue(amount, unit)
    }
    
    var scaleFactor: Double {
        guard
            let food,
            let quantity = food.quantity(for: foodValue)
        else { return 0 }
        return food.nutrientScaleFactor(for: quantity) ?? 0
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tappedSave()
                } label: {
                    Text("Add")
                        .fontWeight(.bold)
                }
            }
            ToolbarItem(placement: .keyboard) {
                stepButtons
            }
        }
    }
    
    func tappedSave() {
        guard let mealID = meal?.id, let food else { return }
        
        Haptics.successFeedback()
        isPresented = false
//        dismiss()
        
//        if let foodItem {
//            /// Update
//        } else {
//            
//            var foodItem = FoodItem()
//            foodItem.amount = foodValue
//            foodItem.food = food
//            foodItem.mealID = mealID
//            
////            FoodItemStore.create(foodItem: foodItem)
//  
//            do {
//                logger.debug("Fetching food")
//                let foodID = foodItem.food.id
//                let foodDescriptor = FetchDescriptor<FoodEntity>(predicate: #Predicate {
//                    $0.uuid == foodID
//                })
//                guard let foodEntity = try context.fetch(foodDescriptor).first else {
//                    logger.error("Could not find food with ID: \(foodID, privacy: .public)")
//                    throw FoodItemStoreError.couldNotFindFood
//                }
//                
//                let mealEntity: MealEntity?
//                if let mealID = foodItem.mealID {
//                    logger.debug("Fetching Meal with ID: \(mealID, privacy: .public)...")
//                    let mealDescriptor = FetchDescriptor<MealEntity>(predicate: #Predicate {
//                        $0.uuid == mealID
//                    })
//                    guard let fetched = try context.fetch(mealDescriptor).first else {
//                        logger.error("Could not find meal with id: \(mealID, privacy: .public)")
//                        return
//                    }
//                    logger.debug("... fetched Meal")
//                    mealEntity = fetched
//                } else {
//                    logger.debug("Meal is nil")
//                    mealEntity = nil
//                }
//                
//                logger.debug("Creating and inserting FoodItemEntity")
//                let foodItemEntity = FoodItemEntity(
//                    uuid: foodItem.id,
//                    foodEntity: foodEntity,
//                    mealEntity: mealEntity,
//                    amount: foodItem.amount,
//                    markedAsEatenAt: foodItem.markedAsEatenDate?.timeIntervalSince1970,
//                    sortPosition: foodItem.sortPosition,
//                    updatedAt: foodItem.updatedDate.timeIntervalSince1970,
//                    badgeWidth: foodItem.badgeWidth
//                )
//                context.insert(foodItemEntity)
//                
//                post(.didAddFoodItem, userInfo: [.foodItem: foodItem])
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    Task {
//                        logger.debug("Saving context")
//                        try context.save()
//                    }
//                }
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
    }
    var form: some View {
        Form {
            Section {
                foodField
                mealField
            }
            quantitySection
            if let food {
                nutrientsSection(food)
            }
        }
    }
    
    func valueString(for nutrient: Nutrient) -> String {
        guard let nutrientValue = food?.value(for: nutrient) else {
            return ""
        }
        let scaled = nutrientValue.value * scaleFactor
        return "\(scaled.cleanAmount) \(nutrientValue.unit.abbreviation)"
    }
    
    func nutrientsSection(_ food: Food) -> some View {
        
        var micros: some View {
            var micros: [Micro] {
                food.micros.compactMap { $0.micro }
            }
            return Group {
                if !micros.isEmpty {
                    DisclosureGroup {
                        ForEach(micros, id: \.self) { micro in
                            HStack {
                                Text(micro.name)
                                    .foregroundStyle(Color(.label))
                                Spacer()
                                Text(valueString(for: .micro(micro)))
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                        }
                    } label: {
                        HStack {
                            Text("Micronutrients")
                            Spacer()
                            Text("\(micros.count)")
                        }
                        .foregroundStyle(Color(.label))
                    }
                }
            }
        }
        
        var energy: some View {
            Section {
                ItemFormEnergyLabel(
                    string: valueString(for: .energy),
                    food: food
                )
            }
        }
        
        var macros: some View {
            Section {
                ForEach(Nutrient.macros, id: \.self) { nutrient in
                    HStack {
                        Text(nutrient.description)
                            .foregroundStyle(Color(.label))
                        Spacer()
                        Text(valueString(for: nutrient))
//                            .foregroundStyle(Color(.secondaryLabel))
                            .foregroundColor(nutrient.macro!.textColor(for: colorScheme))
                            .bold(food.primaryMacro == nutrient.macro)
                    }
                }
            }
        }

        return Group {
            energy
            macros
            micros
        }
    }
    
    var foodField: some View {
        Button {
//            model.reset()
            dismiss()
        } label: {
            ItemFormFoodLabel(food: food)
        }
    }

    var mealField: some View {
        NavigationLink(value: ItemFormRoute.meal) {
            HStack {
                Text("Meal")
                    .foregroundStyle(Color(.label))
                Spacer()
                if let meal {
                    Text(meal.title)
                }
            }
        }
    }
    
    var quantitySection: some View {
        Section {
            HStack(spacing: 4) {
                Text("Quantity")
                    .foregroundStyle(Color(.label))
                textField
                unitPicker
            }
        }
    }
    
    var textField: some View {
        var tapGesture: some Gesture {
            textSelectionTapGesture
        }
        
        return TextField("1", value: $amount, formatter: NumberFormatter.foodValue)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .simultaneousGesture(tapGesture)
    }
    
    var unitPicker: some View {
        
        func button(_ formUnit: FormUnit) -> some View {
            Button {
                unit = formUnit
            } label: {
                Text("\(formUnit.name) (\(formUnit.abbreviation))")
            }
        }
        
        func sizesContent(_ sizes: [FormSize]) -> some View {
            ForEach(sizes.sorted(), id: \.self) { size in
                if size.isVolumePrefixed {
                    Menu {
                        ForEach(VolumeUnitType.primaryUnits, id: \.self) { volumeUnit in
                            Button {
                                unit = .size(size, volumeUnit.defaultVolumeUnit)
                            } label: {
                                Text("\(volumeUnit.name) (\(volumeUnit.abbreviation))")
                            }
                        }
                        Section("Others") {
                            ForEach(VolumeUnitType.secondaryUnits, id: \.self) { volumeUnit in
                                Button {
                                    unit = .size(size, volumeUnit.defaultVolumeUnit)
                                } label: {
                                    Text("\(volumeUnit.name) (\(volumeUnit.abbreviation))")
                                }
                            }
                        }
                    } label: {
                        Text(size.name)
                    }
                } else {
                    Button {
                        unit = .size(size, nil)
                    } label: {
                        Text(size.name)
                    }
                }
            }

        }
        
        @ViewBuilder
        var sizesSections: some View {
            if let sizes = food?.formSizes, !sizes.isEmpty {
                Section("Sizes") {
                    sizesContent(sizes)
                }
            }
        }
        
        @ViewBuilder
        var servingButton: some View {
            if food?.serving != nil {
                Button {
                    unit = .serving
                } label: {
                    Text("Serving")
                }
            }
        }
        
        @ViewBuilder
        var weightsMenu: some View {
            if food?.canBeMeasuredInWeight == true {
                Menu {
                    weightsContent
                } label: {
                    Text("Weights")
                }
            }
        }
        
        var weightsContent: some View {
            ForEach(WeightUnit.allCases, id: \.self) { weightUnit in
                button(.weight(weightUnit))
            }
        }
        
        var volumesContent: some View {
            Group {
                ForEach(VolumeUnitType.primaryUnits, id: \.self) { volumeUnit in
                    button(.volume(volumeUnit.defaultVolumeUnit))
                }
                Section("Others") {
                    ForEach(VolumeUnitType.secondaryUnits, id: \.self) { volumeUnit in
                        button(.volume(volumeUnit.defaultVolumeUnit))
                    }
                }
            }
        }
        
        @ViewBuilder
        var volumesMenu: some View {
            if food?.canBeMeasuredInVolume == true {
                Menu {
                    volumesContent
                } label: {
                    Text("Volumes")
                }
            }
        }
        
        @ViewBuilder
        var menuContents: some View {
            if let food {
                if food.onlySupportsWeights {
                    weightsContent
                } else if food.onlySupportsVolumes {
                    volumesContent
                } else if food.onlySupportsServing {
                    servingButton
                } else {
                    Section {
                        servingButton
                        weightsMenu
                        volumesMenu
                    }
                    sizesSections
                }
            }
        }
        
        return Menu {
            menuContents
        } label: {
            HStack(spacing: 4) {
                Text(unit.abbreviation)
                    .multilineTextAlignment(.trailing)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
            }
            .foregroundStyle(Color(.secondaryLabel))
        }
        .padding(.leading, 5)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .hoverEffect(.highlight)
    }
}

extension ItemForm {

    var stepButtons: some View {
        func stepButton(_ step: Step, _ direction: Direction) -> some View {
            
            var disabled: Bool {
                amount + step.amount > 0
            }
            
            return Button {
                Haptics.selectionFeedback()
                amount += step.amount
            } label: {
                Image(systemName: step.image(in: direction))
            }
            .disabled(disabled)
        }
        
        enum Direction {
            case forward
            case backward
            
            var imagePrefix: String {
                switch self {
                case .backward: "gobackward"
                case .forward: "goforward"
                }
            }
        }
        
        enum Step {
            case small
            case medium
            case large

            var amount: Double {
                switch self {
                case .small: 1
                case .medium: 10
                case .large: 60
                }
            }
            
            var imageSuffix: String {
                switch self {
                case .small: "plus"
                case .medium: "10"
                case .large: "60"
                }
            }
            
            func image(in direction: Direction) -> String {
                "\(direction.imagePrefix).\(imageSuffix)"
            }
        }
        
        return HStack {
            stepButton(.large, .backward)
            stepButton(.medium, .backward)
            stepButton(.small, .backward)
            stepButton(.small, .forward)
            stepButton(.medium, .forward)
            stepButton(.large, .forward)
        }
    }
}

enum ItemFormRoute: Hashable {
    case meal
}

