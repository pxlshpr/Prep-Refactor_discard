import SwiftUI
import SwiftHaptics
import OSLog
import PhotosUI
import Charts

import Camera
import AlertLayer
import FoodDataTypes

let foodModelLogger = Logger(subsystem: "FoodModel", category: "")

struct FoodForm: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

//    @State var model: FoodModel
    @Bindable var model: FoodModel

    @State var path: [FoodFormRoute] = []
    @State var showingCancelConfirmation = false
    @State var showingDeleteConfirmation = false
    @State var showingDensityForm = false
    @State var showingBarcodeScanner = false
    
    @State var showingPhotosPicker = false
    @State var showingCamera = false
    
    @State var showingColumnConfirmation = false
    @State var selectedPhotos: [PhotosPickerItem] = []
    
    @State var hasAppeared = false

    @State var showingImageViewer = false

//    init(_ food: Food) {
//        _model = State(initialValue: FoodModel(food))
//    }
//    
//    init() {
//        _model = State(initialValue: FoodModel())
//    }
    
    var body: some View {
        let _ = Self._printChanges()
        return content
            .onAppear(perform: appeared)
            .frame(idealWidth: 400, idealHeight: 730)
            .interactiveDismissDisabled(model.dismissDisabled)
            
            .photosPicker(
                isPresented: $showingPhotosPicker,
                selection: $selectedPhotos,
                maxSelectionCount: 1,
                matching: .images
            )
            .onChange(of: selectedPhotos, selectedPhotosChanged)
            .sheet(isPresented: $showingImageViewer) { FoodImageViewer(model) }
    }
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.snappy) {
                hasAppeared = true
            }
        }
    }

    func selectedPhotosChanged(oldValue: [PhotosPickerItem], newValue: [PhotosPickerItem]) {
        guard let item = newValue.first else { return }
        Task(priority: .low) { [item] in
            guard let image = try await item.loadImage() else { return }
            await MainActor.run {
                withAnimation(.snappy) {
                    model.startProcessing(image) {
                        showingColumnConfirmation = true
                    }
                }
                selectedPhotos = []
            }
        }
    }
    var content: some View {
        ZStack {
            NavigationStack(path: $path) {
                Group {
                    if hasAppeared {
                        form
                    } else {
                        Color.clear
                    }
                }
                .navigationTitle(title)
                .navigationDestination(for: FoodFormRoute.self, destination: destination)
                .toolbar { toolbarContent }
            }
//            AlertLayer(
//                message: $model.alertMessage,
//                isPresented: $model.isPresentingAlert
//            )
        }
    }
    
    var title: String {
        model.isEditing ? "Edit Food" : "New Food"
    }
    
    var toolbarContent: some ToolbarContent {
        
        var cancelActions: some View {
            Group {
                Button("Discard Changes", role: .destructive) {
                    model.discardNewImages()
//                    model.resetFoodModel()
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {
                }
            }
        }

        var cancelMessage: some View {
            var string: String {
                model.isEditing
                ? "Are you sure you want to discard the changes you have made?"
                : "Are you sure you want to discard this new food?"
            }
            return Text(string)
        }
        
        return Group {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button("Cancel") {
                    Haptics.selectionFeedback()
                    if model.dismissDisabled {
                        showingCancelConfirmation = true
                    } else {
                        dismiss()
                    }
                }
                .confirmationDialog(
                    "",
                    isPresented: $showingCancelConfirmation,
                    actions: { cancelActions },
                    message: { cancelMessage }
                )
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    withAnimation(.snappy) {
                        save()
                    }
                    dismiss()
                } label: {
                    Text(model.isEditing ? "Update" : "Add")
                        .bold()
                }
                .disabled(model.saveDisabled)
            }
        }
    }
    
    func save() {
        if let updatedFood = model.updatedFood {
            do {
//                context.insert(updatedFood)
//                alertMessage = "Food updated successfully."
//                try context.save()
            } catch {
                
            }
        } else {
            
            //TODO: Pre-save validations
            /// [ ] Make sure micros values are 0 if empty
            /// [ ] Clean up URL if need be
            
            do {
//                let food = model.newFood
//                context.insert(food)
//                alertMessage = "Food added successfully."
//                try context.save()
            } catch {
                
            }
        }
//        model.resetFoodModel()
//        showingAlert = true
    }
    
    func destination(route: FoodFormRoute) -> some View {
        Group {
            switch route {
            case .emojiPicker:  emojiPicker
            case .nutrients:    nutrientsForm
            case .sizes:        sizesList
            }
        }
    }
    
    var emojiPicker: some View {
        EmojiPicker(
            categories: [.foodAndDrink, .animalsAndNature]
        ) { emoji in
            Haptics.selectionFeedback()
            model.emoji = emoji
            path = []
        }
    }
    
    var sizesList: some View {
        SizesList()
            .environment(model)
    }
    
    var nutrientsForm: some View {
        NutrientsForm(foodModel: model)
//            .environment(model)
    }
    
    var form: some View {
        Form {
            detailsSection
            nutrientsAndSizesSection
            barcodeSection
            imagesSection
            publishSection
            deleteSection
        }
    }
    
    var imagesSection: some View {
        var camera: some View {
            Camera(
                showTorchButton: true,
                showCaptureAnimation: false
            ) { image in
                showingCamera = false
                withAnimation(.snappy) {
                    model.startProcessing(image) {
                        showingColumnConfirmation = true
                    }
                }
            }
            .frame(idealWidth: 400, idealHeight: 500)
        }

        var addMenu: some View {
            Menu {
                Button {
                    showingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
                Button {
                    showingPhotosPicker = true
                } label: {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }
            } label: {
                Text("Add Image")
            }
            .listRowSeparator(.hidden)
            .disabled(model.isProcessingImage)
            .popover(isPresented: $showingCamera) { camera }
        }
        
        func removeImages(at offsets: IndexSet) {
            model.removeImages(at: offsets)
        }
        
        func imageCell(_ index: Int) -> some View {
            var image: UIImage {
                model.images[index]
            }
            
            var label: some View {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 38, height: 38)
                        .cornerRadius(5)
                    Text("Image")
                        .foregroundStyle(Color(.label))
                    Spacer()
                    if index == model.images.count - 1, model.isProcessingImage {
                        ProgressView()
                            .confirmationDialog(
                                "",
                                isPresented: $showingColumnConfirmation,
                                actions: { model.columnActions },
                                message: { model.columnMessage }
                            )
                    }
                }
            }
            
            return Button {
                model.presentedImageIndex = index
                showingImageViewer = true
            } label: {
                label
            }
        }
        var imageCells: some View {
            ForEach(model.images.indices, id: \.self) { index in
                imageCell(index)
            }
            .onDelete(perform: removeImages)
        }
        
        return Section {
            addMenu
            imageCells
        }
    }
    
    var publishSection: some View {
        var urlField: some View {
            let binding = Binding<String>(
                get: { model.urlString },
                set: { model.urlString = $0 }
            )
            
            return TextField("URL", text: binding)
                .textFieldStyle(.plain)
                .keyboardType(.URL)
                .textContentType(.URL)
        }
        
        var publishToggle: some View {
            let binding = Binding<Bool>(
                get: { model.isPublished },
                set: { newValue in
                    withAnimation(.snappy) {
                        model.isPublished = newValue
                    }
                    model.setSaveDisabled()
                }
            )
            
            return HStack {
                label("Publish", "building.columns", .accentColor)
                Spacer()
                Toggle("", isOn: binding)
            }
        }
        
        
        var goldColor: Color {
            Color(hex: colorScheme == .light ? "A98112" : "FCC200")
        }

        @ViewBuilder
        var footer: some View {
            Button {
                
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Publish this food to be awarded \(Text("subscription tokens").bold()). An image or a URL is required for verification.")
                        .foregroundStyle(Color(.secondaryLabel))
                        .multilineTextAlignment(.leading)
                    Label("Learn more", systemImage: "info.circle")
                        .foregroundStyle(.accent)
                        .padding(2)
                        .hoverEffect(.highlight)
                }
                .font(.footnote)
            }
        }
        
        return Group {
            Section(footer: footer) {
                publishToggle
            }
            if model.isPublished {
                Section {
                    urlField
                }
            }
        }
    }
    
    var barcodeSection: some View {
        
        var barcodeScanner: some View {
            BarcodeScanner { barcodes, image in
                withAnimation(.snappy) {
                    model.barcode = barcodes.first?.string
                    model.addImage(image)
                }
            }
            .frame(idealWidth: 400, idealHeight: 500)
        }
        
        var textField: some View {
            let binding = Binding<String> (
                get: { model.barcode ?? "" },
                set: {
                    model.barcode = $0
                    model.setSaveDisabled()
                }
            )
            return TextField("Barcode", text: binding)
                .textFieldStyle(.plain)
        }
        
        var scannerButton: some View {
            Button {
                showingBarcodeScanner = true
            } label: {
                Image(systemName: "barcode.viewfinder")
            }
        }

        return Section {
            HStack {
                textField
                Spacer()
                scannerButton
                    .popover(isPresented: $showingBarcodeScanner) { barcodeScanner }
            }
        }
    }
    
    var deleteSection: some View {
        
        var actions: some View {
            Group {
                Button("Delete Food", role: .destructive) {
                    dismiss()
                    guard let food = model.foodBeingEdited else { return }
                    model.isDeleting = true
                    Haptics.successFeedback()
                    withAnimation(.snappy) {
//                        alertMessage = "Food deleted successfully."
//                        showingAlert = true
//                        context.delete(food)
                    }
                }
            }
        }

        @ViewBuilder
        var message: some View {
            if let food = model.foodBeingEdited {
                Text("You sure bout that?")
//                Text("\(food.foodItems.count) uses of this will also be deleted. Are you sure you want to delete this food?")
            }
        }
        
        return Group {
            if model.canBeDeleted {
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Text("Delete Food")
                            .padding(.horizontal)
                            .frame(maxHeight: .infinity)
                            .hoverEffect(.highlight)
                            .frame(maxWidth: .infinity)
                            .listRowBackground(EmptyView())
                    }
                    .confirmationDialog(
                        "",
                        isPresented: $showingDeleteConfirmation,
                        actions: { actions },
                        message: { message }
                    )
                }
            }
        }
    }
    
    var sizesLink: some View {
        @ViewBuilder
        var detail: some View {
            if model.sizes.count > 0 {
                Text("\(model.sizes.count)")
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
        
        var greyColor: Color { Color(hex: "6F7E88") }
        var brownColor: Color { Color(hex: "AC8E68") }
        
        return NavigationLink(value: FoodFormRoute.sizes) {
            HStack {
                label("Other Sizes", "takeoutbag.and.cup.and.straw.fill", Color.orange)
                Spacer()
                detail
            }
        }
    }
    
    func label(_ text: String, _ name: String, _ color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: name)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 27, height: 27)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .foregroundStyle(color)
                )
                .foregroundStyle(.white)
            Text(text)
        }
    }

    var sizesSection: some View {
        Section {
            sizesLink
        }
    }

    var nameField: some View {
        var binding: Binding<String> {
            Binding<String>(
                get: { model.name },
                set: {
                    model.name = $0
                    model.setSaveDisabled()
                }
            )
        }

        return TextField("Name", text: binding)
            .textFieldStyle(.plain)
            .simultaneousGesture(textSelectionTapGesture)
    }
    
    var detailField: some View {
        var binding: Binding<String> {
            Binding<String>(
                get: { model.detail },
                set: {
                    model.detail = $0
                    model.setSaveDisabled()
                }
            )
        }

        return TextField("Detail", text: binding)
            .textFieldStyle(.plain)
            .simultaneousGesture(textSelectionTapGesture)
    }
    
    var brandField: some View {
        var binding: Binding<String> {
            Binding<String>(
                get: { model.brand },
                set: {
                    model.brand = $0
                    model.setSaveDisabled()
                }
            )
        }
        
        return TextField("Brand", text: binding)
            .textFieldStyle(.plain)
            .simultaneousGesture(textSelectionTapGesture)
    }
    
    var emojiPickerLink: some View {
        NavigationLink(value: FoodFormRoute.emojiPicker) {
            HStack {
                Text(model.emoji)
                Spacer()
            }
        }
    }

    var detailsSection: some View {
        Section {
            nameField
            detailField
            brandField
            emojiPickerLink
        }
    }
    
    var nutrientsAndSizesSection: some View {
        
        @ViewBuilder
        var details: some View {
            Chart(model.smallChartData, id: \.macro) { macroValue in
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
        
        return Section {
            NavigationLink(value: FoodFormRoute.nutrients) {
                HStack {
                    label("Nutrients", "chart.bar.doc.horizontal", .blue)
                    Spacer()
                    details
                }
            }
            sizesLink
        }
    }
}
