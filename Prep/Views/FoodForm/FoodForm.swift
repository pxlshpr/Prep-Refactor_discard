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

    @Bindable var model: FoodModel

    var body: some View {
//        let _ = Self._printChanges()
        return content
            .onAppear(perform: appeared)
            .frame(idealWidth: 400, idealHeight: 730)
            .interactiveDismissDisabled(model.dismissDisabled)
            
            .photosPicker(
                isPresented: $model.showingPhotosPicker,
                selection: $model.selectedPhotos,
                maxSelectionCount: 1,
                matching: .images
            )
            .onChange(of: model.selectedPhotos, selectedPhotosChanged)
            .sheet(isPresented: $model.showingImageViewer) { FoodImageViewer(model) }
    }
    
    var content: some View {
        ZStack {
            NavigationStack(path: $model.path) {
                Group {
                    if model.hasAppeared {
                        form
                    } else {
                        Color.clear
                    }
                }
                .navigationTitle(model.title)
                .navigationDestination(for: FoodFormRoute.self, destination: destination)
                .toolbar { toolbarContent }
            }
//            AlertLayer(
//                message: $model.alertMessage,
//                isPresented: $model.isPresentingAlert
//            )
        }
    }
    
    @ViewBuilder
    var form: some View {
        switch model.foodType {
        case .food:
            Form {
                detailsSection
                nutrientsAndSizesSection
                barcodeSection
                imagesSection
                publishSection
                deleteSection
            }
        case .recipe:
            Form {
                detailsSection
                foodItemsAndSizesSection
                publishSection
                deleteSection
            }
        case .plate:
            Form {
                detailsSection
                foodItemsAndSizesSection
                publishSection
                deleteSection
            }
        }
    }
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.snappy) {
                model.hasAppeared = true
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
                        model.showingColumnConfirmation = true
                    }
                }
                model.selectedPhotos = []
            }
        }
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
                        model.showingCancelConfirmation = true
                    } else {
                        dismiss()
                    }
                }
                .confirmationDialog(
                    "",
                    isPresented: $model.showingCancelConfirmation,
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
        //TODO: Pre-save validations
        /// [ ] Make sure micros values are 0 if empty
        /// [ ] Clean up URL if need be
        /// [ ] Short alerts

        if let updatedFood = model.updatedFood {
            
            Task.detached(priority: .userInitiated) {
                guard let updatedFood = await FoodsStore.update(updatedFood) else {
                    return
                }
                await MainActor.run {
                    post(.didUpdateFood, userInfo: [.food: updatedFood])
                }
            }
//            alertMessage = "Food updated successfully."

        } else {
            
            let food = model.newFood
            Task.detached(priority: .userInitiated) {
                guard let newFood = await FoodsStore.create(food) else {
                    return
                }
                await MainActor.run {
                    post(.didAddFood, userInfo: [.food: newFood])
                }
            }
//            alertMessage = "Food added successfully."
        }
//        model.reset()
//        showingAlert = true
    }
    
    func destination(route: FoodFormRoute) -> some View {
        Group {
            switch route {
            case .emojiPicker:  emojiPicker
            case .nutrients:    nutrientsForm
            case .sizes:        sizesList
            case .foodItems:    foodItemsForm
            }
        }
    }
    
    var emojiPicker: some View {
        EmojiPicker(
            categories: [.foodAndDrink, .animalsAndNature]
        ) { emoji in
            Haptics.selectionFeedback()
            model.emoji = emoji
            model.path = []
            model.setSaveDisabled()
        }
    }
    
    var sizesList: some View {
        SizesList()
            .environment(model)
    }
    
    var nutrientsForm: some View {
        NutrientsForm(foodModel: model)
    }
    
    var foodItemsForm: some View {
        FoodItemsForm(foodModel: model)
    }
    

    var imagesSection: some View {
        var camera: some View {
            Camera(
                showTorchButton: true,
                showCaptureAnimation: false
            ) { image in
                model.showingCamera = false
                withAnimation(.snappy) {
                    model.startProcessing(image) {
                        model.showingColumnConfirmation = true
                    }
                }
            }
            .frame(idealWidth: IdealCameraWidth, idealHeight: IdealCameraHeight)
        }

        var addMenu: some View {
            Menu {
                Button {
                    model.showingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
                Button {
                    model.showingPhotosPicker = true
                } label: {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }
            } label: {
                Text("Add Image")
            }
            .listRowSeparator(.hidden)
            .disabled(model.isProcessingImage)
            .popover(isPresented: $model.showingCamera) { camera }
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
                                isPresented: $model.showingColumnConfirmation,
                                actions: { model.columnActions },
                                message: { model.columnMessage }
                            )
                    }
                }
            }
            
            return Button {
                model.presentedImageIndex = index
                model.showingImageViewer = true
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
            .frame(idealWidth: IdealCameraWidth, idealHeight: IdealCameraHeight)
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
                model.showingBarcodeScanner = true
            } label: {
                Image(systemName: "barcode.viewfinder")
            }
        }

        return Section {
            HStack {
                textField
                Spacer()
                scannerButton
                    .popover(isPresented: $model.showingBarcodeScanner) { barcodeScanner }
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
                        model.showingDeleteConfirmation = true
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
                        isPresented: $model.showingDeleteConfirmation,
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
            if model.foodType == .food {
                brandField
            }
            emojiPickerLink
        }
    }

    var foodItemsAndSizesSection: some View {
        var foodItemsLink: some View {
            NavigationLink(value: FoodFormRoute.foodItems) {
                HStack {
                    label(model.foodItemsName, "list.bullet", .teal)
                    Spacer()
                    pieChart
                    Text(model.foodItemsCountString)
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
        }
        
        return Section {
            foodItemsLink
            if model.foodType != .plate {
                sizesLink
            }
        }
    }
    
    var nutrientsAndSizesSection: some View {
        
        var nutrientsLink: some View {
            NavigationLink(value: FoodFormRoute.nutrients) {
                HStack {
                    label("Nutrients", "chart.bar.doc.horizontal", .blue)
                    Spacer()
                    pieChart
                }
            }
        }
        
        return Section {
            nutrientsLink
            sizesLink
        }
    }
    
    @ViewBuilder
    var pieChart: some View {
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
    
    var greyColor: Color { Color(hex: "6F7E88") }
    var brownColor: Color { Color(hex: "AC8E68") }
}
