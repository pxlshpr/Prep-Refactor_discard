import SwiftUI
//import SwiftData
import OSLog

import FormSugar
import SwiftHaptics

struct MealForm: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State var refreshDatePicker: Bool = false
    @State var hasAppeared = false

    @State var meal: Meal? = nil
    
    let date: Date
    let initialName: String
    let initialTime: Date

    @State var name: String
    @State var time: Date

    @State var mealTimes: [Date] = []
    
    @State var showingDeleteConfirmation: Bool = false
    @State var isDeleting = false
    
    @State var saveDisabled: Bool
    @State var dismissDisabled = false
    @State var saveDisabledTask: Task<Void, Error>? = nil
    
    init(_ date: Date) {
        self.date = date
        
        let name = Meal.defaultName(at: date)
        _name = State(initialValue: name)
        self.initialName = name
        
        let time = Meal.defaultTime(for: date)
        _time = State(initialValue: time)
        self.initialTime =  time
        
        _saveDisabled = State(initialValue: false)
    }
    
    init(_ meal: Meal) {
        self.date = meal.date
        _meal = State(initialValue: meal)
        _name = State(initialValue: meal.name)
        _time = State(initialValue: meal.time)
        _saveDisabled = State(initialValue: true)
        self.initialName = meal.name
        self.initialTime = meal.time
    }

    @ViewBuilder
    var body: some View {
        content
            .onAppear(perform: appeared)
            .frame(minWidth: 200, idealWidth: 450, minHeight: 250, idealHeight: idealHeight)
            .presentationDetents([.height(detentHeight)])
    }
    
    var idealHeight: CGFloat {
        isEditing ? 430 : 360
    }
    
    @ViewBuilder
    var content: some View {
        if hasAppeared {
            form
        } else {
            Color.clear
        }
    }
    
    var form: some View {
        NavigationStack {
            Form {
                nameSection
                timeSection
                if let meal {
                    deleteSection(meal)
                }
            }
            .navigationTitle(title)
            .scrollDismissesKeyboard(.immediately)
            .interactiveDismissDisabled(dismissDisabled)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }
    
    var detentHeight: CGFloat {
        isEditing ? 450 : 400
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
    
    var isEditing: Bool {
        meal != nil
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    tappedSave()
                } label: {
                    Text(isEditing ? "Save" : "Add")
                        .bold()
                }
                .disabled(saveDisabled)
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
    
    var nameSection: some View {
        let binding = Binding<String>(
            get: { name },
            set: { newValue in
                self.name = newValue
                setSaveDisabled()
            }
        )
        
        return Section {
            TextField("Name", text: binding)
                .textFieldStyle(.plain)
                .simultaneousGesture(textSelectionTapGesture)
        }
    }
    
    var timeSection: some View {
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
    }
    
    func deleteSection(_ meal: Meal) -> some View {
        
        var message: some View {
            Text("\(meal.itemsCountDescription) will also be deleted. Are you sure you want to delete this meal?")
        }
        
        var actions: some View {
            Group {
                Button("Delete Meal", role: .destructive) {
                    dismiss()
                    isDeleting = true
                    Haptics.successFeedback()
                    
                    Task.detached(priority: .high) {
                        guard let updatedDay = await MealsStore.delete(meal) else {
                            return
                        }
                        await MainActor.run {
                            post(.didModifyMeal, userInfo: [.day: updatedDay])
                        }
                    }

                    
                    /// Show Alert
                    withAnimation(.snappy) {
//                        alertMessage = "Food deleted successfully."
//                        showingAlert = true
//                        context.delete(food)
                    }
                }
            }
        }
        
        return Section {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Text("Delete Meal")
                    .frame(maxWidth: .infinity)
            }
            .confirmationDialog(
                "",
                isPresented: $showingDeleteConfirmation,
                actions: { actions },
                message: { message }
            )
        }
    }

    var title: String {
        isEditing ? "Edit Meal" : "New Meal"
    }

    var timeSlider: some View {
        TimeSlider(
            date: date,
            existingTimeSlots: existingTimeSlots,
            currentTime: timeBinding,
            currentTimeSlot: currentTimeSlot
        )
    }
    
    var timeBinding: Binding<Date> {
        Binding<Date>(
            get: { time },
            set: { newValue in
                self.time = newValue
                setSaveDisabled()
            }
        )
    }
    
    var datePicker: some View {
        var picker: some View {
            DatePicker(
                "",
                selection: timeBinding,
                in: dateRangeForPicker,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
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
        || time != initialTime
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
