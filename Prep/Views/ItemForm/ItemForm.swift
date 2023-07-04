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
    
    @State var unit: FormUnit
    @State var meal: Meal? = nil

    @State var food: Food? = nil
    @State var foodItem: FoodItem? = nil

    @Binding var isPresented: Bool
    
    @State var amountString: String
    @State var amountDouble: Double?

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
        _amountDouble = State(initialValue: amount ?? DefaultAmount)
        _amountString = State(initialValue: (amount ?? DefaultAmount).cleanAmount)

        _unit = State(initialValue: unit ?? DefaultUnit)
    }

    var body: some View {
        NavigationStack {
            form
                .navigationTitle("New Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .scrollDismissesKeyboard(.interactively)
                .interactiveDismissDisabled()
        }
    }
    
    var textField: some View {
        let binding = Binding<String>(
            get: { amountString },
            set: { newValue in
                guard !newValue.isEmpty else {
                    amountDouble = nil
                    amountString = newValue
                    return
                }
                guard let double = Double(newValue) else {
                    return
                }
                withAnimation(.snappy) {
                    self.amountDouble = double
                }
                self.amountString = newValue
            }
        )
        return TextField("Required", text: binding)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .simultaneousGesture(textSelectionTapGesture)
    }
    
    var foodValue: FoodValue {
        FoodValue((amountDouble ?? 0), unit)
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
        guard let meal, let food else { return }
        
        Haptics.successFeedback()
        isPresented = false
        dismiss()
        Task {
            if let foodItem {
                /// Update
            } else {
                guard let newFoodItem = await FoodItemsStore.create(food, meal: meal, amount: foodValue) else {
                    return
                }
                post(.didAddFoodItem, userInfo: [.foodItem: newFoodItem])
            }
        }
    }
    
    var form: some View {
        Form {
            Section {
                foodField
                mealField
                quantityField
            }
            if let food {
                nutrientsSection(food)
            }
        }
    }

    func nutrientValue(for nutrient: Nutrient) -> NutrientValue {
        food?.value(for: nutrient) ?? NutrientValue(nutrient: nutrient, value: 0, unit: .g)
    }
    
    func value(for nutrient: Nutrient) -> Double {
        nutrientValue(for: nutrient).value * scaleFactor
    }

    func valueString(for nutrient: Nutrient) -> String {
        "\(value(for: nutrient).cleanAmount) \(nutrientValue(for: nutrient).unit.abbreviation)"
    }
    
    func nutrientsSection(_ food: Food) -> some View {
        
        var microsGroup: some View {
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
        
        var energyField: some View {
            @ViewBuilder
            var pieChart: some View {
                Chart(food.macrosChartData, id: \.macro) { macroValue in
                    SectorMark(
                        angle: .value("kcal", macroValue.kcal),
                        innerRadius: .ratio(0.5),
                        angularInset: 0.5
                    )
                    .cornerRadius(3)
                    .foregroundStyle(by: .value("Macro", macroValue.macro))
                }
                .chartForegroundStyleScale(Macro.chartStyleScale(colorScheme))
                .chartLegend(.hidden)
                .frame(width: 28, height: 28)
            }
            
            return HStack {
                Text("Energy")
                    .foregroundStyle(Color(.label))
                Spacer()
                Color.clear
                    .animatedItemEnergy(
                        value: value(for: .energy),
                        energyUnit: .kcal,
                        isAnimating: isAnimatingAmountChange
                    )
//                pieChart
            }
        }
        
        var macroFields: some View {
            ForEach(Nutrient.macros, id: \.self) { nutrient in
                HStack {
                    Text(nutrient.description)
                        .foregroundStyle(Color(.label))
                    Spacer()
                    Color.clear
                        .animatedItemMacro(
                            value: value(for: nutrient),
                            macro: nutrient.macro!,
                            isPrimary: food.primaryMacro == nutrient.macro,
                            isAnimating: isAnimatingAmountChange
                        )
//                        Text(valueString(for: nutrient))
//                            .foregroundStyle(nutrient.macro!.textColor(for: colorScheme))
//                            .bold(food.primaryMacro == nutrient.macro)
                }
            }
        }

        return Group {
            Section {
                energyField
                macroFields
            }
            microsGroup
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
                        .foregroundStyle(Color(.label))
                }
            }
        }
    }
    
    var quantityField: some View {
        HStack(spacing: 4) {
            Text("Quantity")
                .foregroundStyle(Color(.label))
            textField
            unitPicker
        }
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

    var computedAmount: Double? {
        get {
            return amountDouble
        }
        set {
            amountDouble = newValue
            amountString = newValue?.cleanAmount ?? ""
        }
    }
    
    @State var isAnimatingAmountChange = false
    @State var startedAnimatingAmountChangeAt: Date = Date()

    var stepButtons: some View {
        func stepButton(_ step: Step, _ direction: Direction) -> some View {
            
            var disabled: Bool {
                (amountDouble ?? 0) + step.amount(for: direction) < 0
            }
            
            func tapped() {
                Haptics.selectionFeedback()
                let newAmount = (amountDouble ?? 0) + step.amount(for: direction)
                isAnimatingAmountChange = true
                startedAnimatingAmountChangeAt = Date()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    
                    withAnimation(.snappy) {
                        amountDouble = newAmount
                    }
                    amountString = newAmount.cleanAmount

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        guard Date().timeIntervalSince(self.startedAnimatingAmountChangeAt) >= 0.55
                        else { return }
                        self.isAnimatingAmountChange = false
                    }
                }
            }
            
            return Button {
                tapped()
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
            
            func amount(for direction: Direction) -> Double {
                direction == .forward ? amount : -amount
            }
            
            func imageSuffix(for direction: Direction) -> String {
                switch self {
                case .small: direction == .forward ? "plus" : "minus"
                case .medium: "10"
                case .large: "60"
                }
            }
            
            func image(in direction: Direction) -> String {
                "\(direction.imagePrefix).\(imageSuffix(for: direction))"
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

