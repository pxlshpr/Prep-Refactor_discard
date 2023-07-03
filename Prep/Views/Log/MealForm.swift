import SwiftUI
import SwiftData
import OSLog

import FormSugar
import SwiftHaptics

struct MealForm: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context

    @Bindable var model: MealModel
    
    @State var refreshDatePicker: Bool = false
    @State var hasAppeared = false

//    @State var day: DayEntity? = nil
    
    init(model: MealModel) {
        self.model = model
    }
    
    var meal: Meal? { model.meal }
    var date: Date { model.date }

    var mealTimes: [Date] { model.mealTimes }
    
    @ViewBuilder
    var body: some View {
        content
            .onAppear(perform: appeared)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.snappy) {
                hasAppeared = true
            }
        }
//        Task {
//            let day = try await Database.shared.fetchOrCreateDay(for: date)
//            await MainActor.run {
//                guard let mainContextDay = context.object(with: day.objectID) as? DayEntity else {
//                    fatalError()
//                }
//                self.day = mainContextDay
//            }
//        }
    }
    
    var nameTextField: some View {
        TextField("Name", text: $model.name)
            .textFieldStyle(.plain)
            .showClearButton($model.name)
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
            currentTime: $model.time,
            currentTimeSlot: currentTimeSlot
        )
    }
    
    var datePicker: some View {
        var picker: some View {
            DatePicker(
                "",
                selection: $model.time,
                in: dateRangeForPicker,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .onChange(of: model.time, onChangeOfTime)
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
                .opacity(model.time.startOfDay != date.startOfDay ? 1 : 0)
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
        
//        if let meal {
//            /// Update
//        } else {
////            MealStore.create(
////                name: model.name,
////                time: model.time,
////                date: date
////            )
//            
//            
//            let logger = Logger(subsystem: "MealForm", category: "tappedSave")
//            do {
//                
//                let calendarDayString = date.calendarDayString
//                let descriptor = FetchDescriptor(predicate: #Predicate<DayEntity> {
//                    $0.calendarDayString == calendarDayString
//                })
//                
//                logger.debug("Fetching day with calendarDayString: \(calendarDayString)")
//                let days = try context.fetch(descriptor)
//                guard days.count <= 1 else {
//                    fatalError("Duplicate days for: \(date.calendarDayString)")
//                }
//                
//                let fetchedDay = days.first
//                let dayEntity: DayEntity
//                if let fetchedDay {
//                    logger.info("Day was fetched")
//                    dayEntity = fetchedDay
//                } else {
//                    logger.info("Day wasn't fetched, creating ...")
//                    let newDay = DayEntity(calendarDayString: date.calendarDayString)
//                    logger.debug("Inserting new DayEntity...")
//                    context.insert(newDay)
//                    dayEntity = newDay
//                }
//                
//                logger.debug("Now that we have dayEntity, creating MealEntity")
//                
//                let mealEntity = MealEntity(
//                    dayEntity: dayEntity,
//                    name: model.name,
//                    time: model.time.timeIntervalSince1970
//                )
//                logger.debug("Inserting new MealEntity with id: \(mealEntity.uuid, privacy: .public)...")
//                context.insert(mealEntity)
//                
//                logger.debug("Returning the newly created Meal")
//                let meal = Meal(
//                    mealEntity,
//                    dayEntity: dayEntity,
//                    foodItems: []
//                )
//                post(.didAddMeal, userInfo: [.meal: meal])
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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

    func onChangeOfTime(oldValue: Date, newValue: Date) {
        /// For some reason, not having this `onChange` modifier doesn't update the `time` when we pick one using the `DatePicker`, so we're leaving it in here
    }
    
    var existingTimeSlots: [Int] {
        mealTimes.map {
            $0.timeSlot(within: date)
        }
    }

    var currentTimeSlot: Int {
        model.time.timeSlot(within: date)
    }
    
    var saveIsDisabled: Bool {
        if model.name.isEmpty {
            return true
        }
        
        if let meal {
            if meal.name == model.name
                && meal.time.equalsIgnoringSeconds(model.time) {
                return true
            }
        }
        
        return false
    }
    
    var saveButton: some View {
        var color: Color {
            (colorScheme == .light && saveIsDisabled)
            ? .black
            : .white
        }
        
        var opacity: CGFloat {
            saveIsDisabled
            ? (colorScheme == .light ? 0.2 : 0.2)
            : 1
        }
        var background: some View {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(Color.accentColor.gradient)
        }

        return Button {
            tappedSave()
        } label: {
            Text(meal == nil ? "Add" : "Save")
                .bold()
                .foregroundStyle(color)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(background)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, K.FormStyledSection.horizontalOuterPadding)
        .disabled(saveIsDisabled)
        .opacity(opacity)
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
