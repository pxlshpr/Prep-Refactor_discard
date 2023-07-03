import SwiftUI
import UIKit
import SwiftHaptics

extension FoodModel {
    
    func startProcessing(_ image: UIImage, showColumnConfirmation: @escaping () -> ()) {
        
        addImage(image)

        isProcessingImage = true
        processingStatus = "Scanning"
        
        Task.detached(priority: .userInitiated) {
            let textSet = try await image.recognizedTextSet(for: .accurate, includeBarcodes: true)
            await MainActor.run {
                self.processingStatus = "Extracting from \(textSet.texts.count) texts…"
            }
            let scanResult = textSet.scanResult
            self.scanResult = scanResult
            
            if scanResult.columnCount == 1 {
                await self.extractNutrients()
            } else {
                showColumnConfirmation()
            }
        }
    }
    
    func extractNutrients(_ column: Int = 1) async {
        guard let scanResult else { return }
        
        let extractedNutrients = scanResult.extractedNutrientsForColumn(
            column,
            includeSingleColumnValues: true,
            ignoring: []
        )
        
        let sizes = scanResult.allSizes(at: column)
        let density = scanResult.density
        let amount = scanResult.amount(for: column)
        let serving = scanResult.serving(for: column)
        let barcodes = scanResult.barcodeStrings
        
        await MainActor.run {
            fillInSizes(sizes)
            if let amount {
                fillInAmount(amount)
            }
            if let serving {
                fillInServing(serving)
            }
            if let density {
                fillIn(density)
            }
            fillInBarcodes(barcodes)

            fillIn(extractedNutrients)
            processingStatus = "\(extractedNutrients.count) nutrients extracted 🥳"
            isProcessingImage = false
            
            Haptics.feedback(style: .rigid)
            
            SoundPlayer.play(.letterpressSwoosh1)

            alertMessage = "\(extractedNutrients.count) nutrients extracted"
            isPresentingAlert = true
        }
    }
}

extension FoodModel {
    var columnActions: some View {
        
        var column1Title: String {
            scanResult?.headerTitle1 ?? "Column 1"
        }

        var column2Title: String {
            scanResult?.headerTitle2 ?? "Column 2"
        }

        return Group {
            Button(column1Title) {
                Task {
                    await self.extractNutrients(1)
                }
            }
            Button(column2Title) {
                Task {
                    await self.extractNutrients(2)
                }
            }
            Button("Cancel", role: .cancel) {
                self.scanResult = nil
                self.processingStatus = ""
                self.isProcessingImage = false
            }
        }
    }

    var columnMessage: some View {
        Text("Which column would you like to use?")
    }
}
