import SwiftUI
import PhotosUI
import Charts

import SwiftHaptics
import Camera
import VisionSugar
import FoodDataTypes
import FoodLabelScanner

struct NutrientsForm: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable var foodModel: FoodModel

    @State var showingMicroPicker = false
    @State var showingCamera = false
    @State var showingPhotosPicker = false
    
    @State var showingColumnConfirmation = false
    
//    @State var isProcessingImage = false
//    @State var processingStatus: String = ""
//    @State var scanSoundEffect: AVAudioPlayer?
    @State var selectedPhotos: [PhotosPickerItem] = []

    var body: some View {
        form
            .navigationTitle("Nutrients")
            .toolbar { toolbarContent }
            .photosPicker(
                isPresented: $showingPhotosPicker,
                selection: $selectedPhotos,
                maxSelectionCount: 1,
                matching: .images
            )
            .onChange(of: selectedPhotos) { oldValue, newValue in
                guard let item = newValue.first else { return }
                Task(priority: .low) { [item] in
                    guard let image = try await item.loadImage() else { return }
                    await MainActor.run {
                        foodModel.startProcessing(image) {
                            showingColumnConfirmation = true
                        }
                        selectedPhotos = []
                    }
                }
            }
    }
    
    var form: some View {
        Form {
            amountAndServingSection
            energySection
            macrosSection
            pieChartSection
            microsSection
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    var amountAndServingSection: some View {
        Section {
            ServingField(foodModel: foodModel)
            if foodModel.amountUnit == .serving {
                ServingField(isServing: true, foodModel: foodModel)
            }
        }
    }
    
    @ViewBuilder
    var pieChartSection: some View {
        if foodModel.shouldShowPieChart {
            Section {
                Chart(foodModel.macrosChartData, id: \.macro) { macroValue in
                    SectorMark(
                        angle: .value("kcal", macroValue.kcal),
                        angularInset: 1.5
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Macro", macroValue.macro))
                }
                .chartForegroundStyleScale(Macro.chartStyleScale(colorScheme))
                .chartLegend(position: .trailing, alignment: .center)
                .padding(.vertical, 5)
            }
        }
    }
    
    var microsSection: some View {
        Group {
            ForEach(foodModel.microGroups, id: \.self) { group in
                microGroupSection(for: group)
            }
            addMicrosSection
        }
    }
    
    var energySection: some View {
        Section {
            NutrientField($foodModel.energy)
                .environment(foodModel)
        }
    }
    
    var macrosSection: some View {
        Section("Macros") {
            NutrientField($foodModel.carb)
                .environment(foodModel)
            NutrientField($foodModel.fat)
                .environment(foodModel)
            NutrientField($foodModel.protein)
                .environment(foodModel)
        }
    }
    
    var addMicrosSection: some View {
        @ViewBuilder
        var header: some View {
            if foodModel.micros.isEmpty {
                Text("Micronutrients")
            } else {
                EmptyView()
            }
        }
        
        var section: some View {
            Section(header: header) {
                Button {
                    showingMicroPicker = true
                } label: {
                    Text("Add Micronutrients")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .popover(isPresented: $showingMicroPicker) { microPicker }
            }
        }
        
        return Group {
            if !foodModel.availableMicroGroupsToAdd.isEmpty {
                section
            }
        }
    }
    
    func microGroupSection(for group: MicroGroup) -> some View {
        var nutrientValues: [NutrientValue] {
            foodModel.nutrientValues(for: group)
        }

        func removeRows(at offsets: IndexSet) {
            let micros = offsets
                .map { nutrientValues[$0] }
                .compactMap { $0.micro }
            withAnimation {
                foodModel.remove(micros)
            }
        }
        
        func index(of nutrientValue: NutrientValue) -> Int? {
            foodModel.micros.firstIndex(where: {
                $0.micro == nutrientValue.micro
            })
        }

        return Section(group.name) {
            ForEach(nutrientValues, id: \.self.nutrient) { nutrientValue in
                if let index = index(of: nutrientValue) {
                    NutrientField($foodModel.micros[index])
                        .environment(foodModel)
                }
            }
            .onDelete(perform: removeRows)
        }
    }
    
    var microPicker: some View {
        MicroPicker()
            .environment(foodModel)
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    if foodModel.processingStatus != "" && foodModel.isProcessingImage {
                        ProgressView()
                    }
                    if !foodModel.isProcessingImage {
                        HStack {
                            Button {
                                showingCamera = true
                            } label: {
                                Image(systemName: "camera.fill")
                            }
                            .popover(isPresented: $showingCamera) { camera }

                            Button {
                                showingPhotosPicker = true
                            } label: {
                                Image(systemName: "photo.on.rectangle")
                            }
                            Spacer()
                        }
                    }
                }
                .confirmationDialog(
                    "",
                    isPresented: $showingColumnConfirmation,
                    actions: { foodModel.columnActions },
                    message: { foodModel.columnMessage }
                )
            }
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()
                    Text(foodModel.processingStatus)
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .opacity(0)
                }
            }
        }
    }
    
    var camera: some View {
        Camera(
            showTorchButton: true,
            showCaptureAnimation: false
        ) { image in
            showingCamera = false
            foodModel.startProcessing(image) {
                showingColumnConfirmation = true
            }
        }
        .frame(idealWidth: 400, idealHeight: 500)
    }
    
}

//MARK: - Scan

//import AVFoundation
//
//extension NutrientsForm {
//    
//    func selectedPhotosChanged(oldValue: [PhotosPickerItem], newValue: [PhotosPickerItem]) {
//        guard let item = newValue.first else { return }
//        
//        Task(priority: .low) { [item] in
//            guard let image = try await loadImage(pickerItem: item) else { return }
//            
//            await MainActor.run {
//                startProcessing(image)
//                selectedPhotos = []
//            }
//        }
//    }
//   
//    func loadImage(pickerItem: PhotosPickerItem) async throws -> UIImage? {
//        guard let data = try await pickerItem.loadTransferable(type: Data.self) else {
//            return nil
//        }
//        guard let image = UIImage(data: data) else {
//            return nil
//        }
//        return image
//    }
//
//    func startProcessing(_ image: UIImage) {
//        
//        foodModel.images.append(image)
//
//        isProcessingImage = true
//        processingStatus = "Scanning"
//        
//        Task.detached(priority: .userInitiated) {
//            let textSet = try await image.recognizedTextSet(for: .accurate, includeBarcodes: true)
//            await MainActor.run {
//                processingStatus = "Extracting from \(textSet.texts.count) texts…"
//            }
//            let scanResult = textSet.scanResult
//            foodModel.scanResult = scanResult
//            
//            if scanResult.columnCount == 1 {
//                await extractNutrients()
//            } else {
//                showingColumnConfirmation = true
//            }
//        }
//    }
//    
//    func extractNutrients(_ column: Int = 1) async {
//        guard let scanResult = foodModel.scanResult else { return }
//        
//        let extractedNutrients = scanResult.extractedNutrientsForColumn(
//            column,
//            includeSingleColumnValues: true,
//            ignoring: foodModel.attributesToIgnore
//        )
//        await MainActor.run {
//            foodModel.fillIn(extractedNutrients)
//            processingStatus = "\(extractedNutrients.count) nutrients extracted 🥳"
//            isProcessingImage = false
//            
//            Haptics.feedback(style: .rigid)
//            
////                let soundFile = "wellDone.wav"
////                let soundFile = "chord.wav"
//            let soundFile = "letterpress_swoosh1.wav"
////                let soundFile = "letterpress_swoosh2.wav"
//
//            guard let path = Bundle.main.path(forResource: soundFile, ofType: nil) else {
//                fatalError()
//            }
//            let url = URL(fileURLWithPath: path)
//
//            do {
//                scanSoundEffect = try AVAudioPlayer(contentsOf: url)
//                scanSoundEffect?.play()
//            } catch {
//                fatalError()
//            }
//        }
//    }
//    
//}
