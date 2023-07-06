import SwiftUI
//import SwiftData
import OSLog

import FormSugar
import SwiftHaptics

struct MealForm: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

//    @Bindable var model: MealModel
//    @State var day: DayEntity? = nil
        
    @State var refreshDatePicker: Bool = false
    @State var hasAppeared = false

    @State var meal: Meal? = nil
    
    let initialName: String
    let date: Date
    
    @State var name: String
    @State var time: Date

    @State var mealTimes: [Date] = []
    
    @State var isDeleting = false
    @State var saveDisabled: Bool
    @State var dismissDisabled = false
    @State var saveDisabledTask: Task<Void, Error>? = nil

    init(_ date: Date) {
        self.date = date
        
        let name = Meal.defaultName(at: date)
        _name = State(initialValue: name)
        self.initialName = name
        
        _time = State(initialValue: date)
        
        _saveDisabled = State(initialValue: false)
    }
    
    init(_ meal: Meal) {
        self.date = meal.date
        _meal = State(initialValue: meal)
        _name = State(initialValue: meal.name)
        _time = State(initialValue: meal.time)
        _saveDisabled = State(initialValue: true)
        self.initialName = meal.name
    }

    @ViewBuilder
    var body: some View {
        content
            .onAppear(perform: appeared)
            .frame(minWidth: 200, idealWidth: 450, minHeight: 250, idealHeight: 340)
            .presentationDetents([.height(detentHeight)])
    }
    
    var detentHeight: CGFloat {
        meal == nil ? 400 : 450
    }
    
    
    @ViewBuilder
    var content: some View {
        if hasAppeared {
            form
        } else {
            Color.clear
        }
    }
    
    func appeared() {
        fetchDay()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.snappy) {
                hasAppeared = true
            }
        }
    }
    
    func fetchDay() {
        Task.detached(priority: .high) {
            guard let day = await DaysStore.day(for: date) else {
                return
            }
            self.mealTimes = day.meals
                .filter {
                    guard let meal else { return false }
                    return $0.id != meal.id
                }
                .map { $0.time }
        }
    }
    
    var nameTextField: some View {
        TextField("Name", text: $name)
            .textFieldStyle(.plain)
            .showClearButton($name)
    }
    
    var form: some View {
        NavigationStack {
            Form {
                Section {
                    nameTextField
                }
                Section {
                    VStack {
                        HStack(spacing: 10) {
                            Text("Time")
                                .foregroundStyle(Color(.secondaryLabel))
                            datePicker
                        }
                        timeSlider
                    }
                }
                if meal != nil {
                    Section {
                        Button(role: .destructive) {
                            
                        } label: {
                            Text("Delete Meal")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        tappedSave()
                    } label: {
                        Text("Add")
                            .bold()
                    }
                }
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
    
    var title: String {
        meal == nil ? "New Meal" : "Edit Meal"
    }

    var timeSlider: some View {
        TimeSlider(
            date: date,
            existingTimeSlots: existingTimeSlots,
            currentTime: $time,
            currentTimeSlot: currentTimeSlot
        )
    }
    
    var datePicker: some View {
        var picker: some View {
            DatePicker(
                "",
                selection: $time,
                in: dateRangeForPicker,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
//            .onChange(of: time, timeChanged)
            .id(refreshDatePicker)
        }
        
        var pastMidnightLabel: some View {
            Text("Past Midnight")
                .bold()
                .font(.footnote)
                .foregroundStyle(.black)
                .padding(.vertical, 4)
                .padding(.horizontal, 7)
                .background(
                    RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                        .fill(.yellow)
                )
                .opacity(time.startOfDay != date.startOfDay ? 1 : 0)
        }
        
        return ZStack {
            HStack {
                picker
                Spacer()
            }
            HStack {
                Spacer()
                pastMidnightLabel
            }
        }
    }
    
    var dateRangeForPicker: ClosedRange<Date> {
        let start = date.startOfDay
        let end = date.moveDayBy(1).atEndOfWeeHours
        return start...end
    }
    
    func tappedSave() {
        /// This is to ensure that the date picker is dismissed if a confirmation button
        /// is tapped while it's presented (otherwise causing the dismissal to fail)
        refreshDatePicker.toggle()
        Haptics.successFeedback()
        dismiss()
        
        Task.detached {
            if let meal {
                /// Update
                guard let (updatedMeal, updatedDay) = await MealsStore.update(meal, name: name, time: time)
                else { return }
                await MainActor.run {
                    post(.didModifyMeal, userInfo: [
                        .meal: updatedMeal,
                        .day: updatedDay
                    ])
                }
            } else {
                /// Create
                guard let (newMeal, updatedDay) = await MealsStore.create(name, at: time, on: date)
                else { return }
                
                await MainActor.run {
                    post(.didModifyMeal, userInfo: [
                        .meal: newMeal,
                        .day: updatedDay
                    ])
                }
            }
        }
    }
    
    var existingTimeSlots: [Int] {
        mealTimes.map {
            $0.timeSlot(within: date)
        }
    }

    var currentTimeSlot: Int {
        time.timeSlot(within: date)
    }
}

import SwiftSugar

extension MealForm {
    func delayedSetSaveDisabled() {
        saveDisabledTask?.cancel()
        saveDisabledTask = Task.detached(priority: .userInitiated) {
            /// sleep to let the animation complete first
            try await sleepTask(0.2)
            try Task.checkCancellation()
            await MainActor.run {
                self.setSaveDisabled()
            }
        }
    }

    func setSaveDisabled() {
        guard !isDeleting else {
            saveDisabled = true
            dismissDisabled = true
            return
        }
        saveDisabled = shouldDisableSave
        dismissDisabled = shouldDisableDismiss
    }
    
    func hasPendingChanges(from meal: Meal) -> Bool {
        name != meal.name
        || time != meal.time
    }
    
    var isValid: Bool {
        /// Name cannot be empty
        guard !name.isEmpty else { return false }
        
        return true
    }
    
    var shouldDisableSave: Bool {
        if let meal {
            /// Can be saved if we have pending changes
            !hasPendingChanges(from: meal)
        } else {
            !isValid
        }
    }
    
    var shouldDisableDismiss: Bool {
        if let meal {
            /// Can be saved if we have pending changes
            hasPendingChanges(from: meal)
        } else {
            hasEnteredData
        }
    }
    
    var hasEnteredData: Bool {
        name != initialName
        || time != date /// since `date` is the initial time we set this form with for a new Meal
    }
}

struct TextFieldClearButton: ViewModifier {
    @Binding var fieldText: String

    func body(content: Content) -> some View {
        content
            .overlay {
                if !fieldText.isEmpty {
                    HStack {
                        Spacer()
                        Button {
                            fieldText = ""
                        } label: {
                            Image(systemName: "multiply.circle.fill")
                        }
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(.trailing, 4)
                    }
                }
            }
    }
}

extension View {
    func showClearButton(_ text: Binding<String>) -> some View {
        self.modifier(TextFieldClearButton(fieldText: text))
    }
}
