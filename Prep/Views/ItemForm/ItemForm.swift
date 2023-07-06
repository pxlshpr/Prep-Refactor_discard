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
    
    @FocusState var isFocused: Bool
    
    @State var unit: FormUnit
    @State var meal: Meal? = nil

//    @State var food: Food? = nil
    @State var food: Food
    @State var foodItem: FoodItem? = nil

    @State var hasAppeared = false
    @Binding var isPresented: Bool
    
    @State var amountString: String
    @State var amountDouble: Double?

    @State var isAnimatingAmountChange = false
    @State var startedAnimatingAmountChangeAt: Date = Date()
    
    @State var quickAmounts: [FoodValue] = []
    @State var showingShortcuts = false
    
    @State var isDeleting = false
    @State var saveDisabled: Bool
    @State var dismissDisabled = false
    @State var saveDisabledTask: Task<Void, Error>? = nil

    let initialFoodValue: FoodValue
    
    /// Creating new items
    init(
        isPresented: Binding<Bool>,
        meal: Meal?,
        food: Food
    ) {
        _isPresented = isPresented
        _meal = State(initialValue: meal)
        _food = State(initialValue: food)
        

        let amount: Double
        let unit: FormUnit
        /// Either set the latest used quantity or the default one
        if let lastAmount = food.lastAmount {
            amount = lastAmount.value
            unit = lastAmount.formUnit(for: food) ?? DefaultUnit
        } else {
            let quantity = food.defaultQuantity
            amount = quantity?.value ?? DefaultAmount
            unit = quantity?.unit.formUnit ?? DefaultUnit
        }
        _amountDouble = State(initialValue: amount)
        _amountString = State(initialValue: amount.cleanAmount)

        _unit = State(initialValue: unit)
        
        _saveDisabled = State(initialValue: false)
        
        initialFoodValue = FoodValue(amount, unit)
    }

    /// Editing existing items
    init(
        isPresented: Binding<Bool>,
        foodItem: FoodItem,
        meal: Meal
    ) {
        _isPresented = isPresented
        _meal = State(initialValue: meal)
        _food = State(initialValue: foodItem.food)
        _foodItem = State(initialValue: foodItem)
        
        _amountDouble = State(initialValue: foodItem.amount.value)
        _amountString = State(initialValue: foodItem.amount.value.cleanAmount)

        if let unit = foodItem.amount.formUnit(for: foodItem.food) {
            _unit = State(initialValue: unit)
        } else {
            _unit = State(initialValue: DefaultUnit)
        }
        
        _saveDisabled = State(initialValue: true)

        initialFoodValue = foodItem.amount
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
        .scrollDismissesKeyboard(.immediately)
        .interactiveDismissDisabled(dismissDisabled)
        .onAppear(perform: appeared)
        .frame(idealWidth: 400, idealHeight: 800)
        .presentationDetents([.medium, .fraction(0.90)])
        .onChange(of: isFocused, isFocusedChanged)
    }
    
    func isFocusedChanged(oldValue: Bool, newValue: Bool) {
        let delay = newValue == true ? 0.2 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.snappy) {
                showingShortcuts = newValue
            }
        }
    }
    
    var isEditing: Bool {
        foodItem != nil
    }
    
    var title: String {
        isEditing ? "Edit Entry" : "New Entry"
    }
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.snappy) {
                hasAppeared = true
            }
        }
        Task.detached(priority: .background) {
            let usedAmounts = await FoodItemsStore.usedAmounts(for: food).prefix(5)
            await MainActor.run {
                var amounts = Array(usedAmounts) + food.defaultAmounts
                amounts.removeDuplicates()
                self.quickAmounts = amounts
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        if hasAppeared {
            form
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
                
                delayedSetSaveDisabled()
            }
        )
        return TextField("Required", text: binding)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .simultaneousGesture(textSelectionTapGesture)
    }
    
    var foodValue: FoodValue {
        FoodValue((amountDouble ?? 0), unit)
    }
    
    var scaleFactor: Double {
        guard let quantity = food.quantity(for: foodValue) else { return 0 }
        return food.nutrientScaleFactor(for: quantity) ?? 0
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tappedSave()
                } label: {
                    Text(isEditing ? "Save" : "Add")
                        .fontWeight(.bold)
                }
                .disabled(saveDisabled)
            }
//            ToolbarItem(placement: .keyboard) {
//                stepButtons
//            }
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        }
    }
    
    func tappedSave() {
        guard let meal else { return }
        
        Haptics.successFeedback()
        isPresented = false
        
        Task.detached {
            if let foodItem {
                /// Update
                guard let (updatedFoodItem, updatedDay) = await FoodItemsStore.update(foodItem, with: foodValue
                ) else {
                    return
                }
                await MainActor.run {
                    if let updatedDay {
                        post(.didAddFoodItem, userInfo: [
                            .foodItem: updatedFoodItem,
                            .day: updatedDay
                        ])
                    }
                }
                
            } else {
                /// Create
                guard let (newFoodItem, updatedDay) = await FoodItemsStore.create(
                    food, meal: meal, amount: foodValue
                ) else {
                    return
                }
                
                await MainActor.run {
                    post(.didAddFoodItem, userInfo: [
                        .foodItem: newFoodItem,
                        .day: updatedDay
                    ])
                }
            }
        }
    }
    
    var form: some View {
        Form {
            Section {
                foodField
                mealField
                quantityField
                incrementField
            }
            nutrientsSection
        }
        .scrollIndicators(.hidden)
    }
    
    var incrementField: some View {
        Group {
            if showingShortcuts {
                stepButtons
            }
                quickAmountsPicker
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
//            }
        }
    }
    
    var quickAmountsPicker: some View {
        func button(for amount: FoodValue) -> some View {
            var string: String {
                amount.description(with: food)
            }
            
            var label: some View {
                Text(string)
                    .foregroundStyle(Color(.label))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color(.secondarySystemFill))
                    )
            }
            
            return Button {
                Haptics.selectionFeedback()
//                SoundPlayer.play(.clearTap)
                SoundPlayer.play(.letterpressClick1)
                setAmount(amount.value)
                if let unit = amount.formUnit(for: food) {
                    self.unit = unit
                }
                delayedSetSaveDisabled()
            } label: {
                label
            }
        }
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(quickAmounts, id: \.self) { amount in
                    button(for: amount)
                }
            }
        }
        .contentMargins(.all,
                        EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20),
                        for: .scrollContent
        )
    }

    func nutrientValue(for nutrient: Nutrient) -> NutrientValue {
        food.value(for: nutrient) ?? NutrientValue(nutrient: nutrient, value: 0, unit: .g)
    }
    
    func value(for nutrient: Nutrient) -> Double {
        nutrientValue(for: nutrient).value * scaleFactor
    }

    func valueString(for nutrient: Nutrient) -> String {
        "\(value(for: nutrient).cleanAmount) \(nutrientValue(for: nutrient).unit.abbreviation)"
    }
    
    var nutrientsSection: some View {
        
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
    
    @ViewBuilder
    var foodField: some View {
        HStack(alignment: .top) {
            Text("Food")
                .foregroundStyle(Color(.label))
            Spacer()
            Text(food.foodName)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .multilineTextAlignment(.trailing)
    }

    var mealField: some View {
        HStack {
            Text("Meal")
                .foregroundStyle(Color(.label))
            Spacer()
            if let meal {
                Text(meal.title)
                    .foregroundStyle(Color(.secondaryLabel))
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
    
    func setUnit(_ formUnit: FormUnit) {
        withAnimation(.snappy) {
            unit = formUnit
        }
        delayedSetSaveDisabled()
    }
    var unitPicker: some View {
        
        func button(_ formUnit: FormUnit) -> some View {
            Button {
                setUnit(formUnit)
            } label: {
                Text("\(formUnit.name) (\(formUnit.abbreviation))")
            }
        }
        
        var sizesContent: some View {
            ForEach(food.formSizes.sorted(), id: \.self) { size in
                if size.isVolumePrefixed {
                    Menu {
                        ForEach(VolumeUnitType.primaryUnits, id: \.self) { volumeUnit in
                            Button {
                                setUnit(.size(size, volumeUnit.defaultVolumeUnit))
                            } label: {
                                Text("\(volumeUnit.name) (\(volumeUnit.abbreviation))")
                            }
                        }
                        Section("Others") {
                            ForEach(VolumeUnitType.secondaryUnits, id: \.self) { volumeUnit in
                                Button {
                                    setUnit(.size(size, volumeUnit.defaultVolumeUnit))
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
                        withAnimation {
                            setUnit(.size(size, nil))
                        }
                    } label: {
                        Text(size.name)
                    }
                }
            }

        }
        
        @ViewBuilder
        var sizesSections: some View {
            if !food.formSizes.isEmpty {
                Section("Sizes") {
                    sizesContent
                }
            }
        }
        
        @ViewBuilder
        var servingButton: some View {
            if food.canBeMeasuredInServings {
                Button {
                    setUnit(.serving)
                } label: {
                    Text("Serving")
                }
            }
        }
        
        @ViewBuilder
        var weightsMenu: some View {
            if food.canBeMeasuredInWeight {
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
            if food.canBeMeasuredInVolume {
                Menu {
                    volumesContent
                } label: {
                    Text("Volumes")
                }
            }
        }
        
        @ViewBuilder
        var menuContents: some View {
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
    
    enum StepButtonDirection {
        case forward
        case backward
        
        var imagePrefix: String {
            switch self {
            case .backward: "gobackward"
            case .forward: "goforward"
            }
        }
        
        var sound: SoundPlayer.Sound {
            switch self {
            case .backward: .letterpressClick2
            case .forward: .letterpressClick1
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
        
        func amount(for direction: StepButtonDirection) -> Double {
            direction == .forward ? amount : -amount
        }
        
        func imageSuffix(for direction: StepButtonDirection) -> String {
            switch self {
            case .small: direction == .forward ? "plus" : "minus"
            case .medium: "10"
            case .large: "60"
            }
        }
        
        func image(in direction: StepButtonDirection) -> String {
            "\(direction.imagePrefix).\(imageSuffix(for: direction))"
        }
    }
}

extension ItemForm {
    func tappedStepButton(_ step: Step, _ direction: StepButtonDirection) {
        
        Haptics.selectionFeedback()
        SoundPlayer.play(direction.sound)
        
        let newAmount = (amountDouble ?? 0) + step.amount(for: direction)
        
        isAnimatingAmountChange = true
        startedAnimatingAmountChangeAt = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            setAmount(newAmount)
        }
        
        delayedSetSaveDisabled()
    }
    
    func setAmount(_ amount: Double) {
        withAnimation(.snappy) {
            amountDouble = amount
        }
        amountString = amount.cleanAmount

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard Date().timeIntervalSince(self.startedAnimatingAmountChangeAt) >= 0.55
            else { return }
            self.isAnimatingAmountChange = false
        }
    }

    func shouldDisableStepButton(_ step: Step, direction: StepButtonDirection) -> Bool {
        (amountDouble ?? 0) + step.amount(for: direction) < 0
    }

    func stepButton(_ step: Step, _ direction: StepButtonDirection) -> some View {
        Button {
            tappedStepButton(step, direction)
        } label: {
            Image(systemName: step.image(in: direction))
                .font(.system(size: 25, weight: .regular))
                .frame(maxWidth: .infinity)
        }
        .disabled(shouldDisableStepButton(step, direction: direction))
        .buttonStyle(.borderless)
    }

    var stepButtons: some View {
        HStack {
            stepButton(.large, .backward)
            stepButton(.medium, .backward)
            stepButton(.small, .backward)
            stepButton(.small, .forward)
            stepButton(.medium, .forward)
            stepButton(.large, .forward)
        }
    }
}
