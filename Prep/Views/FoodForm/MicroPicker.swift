import SwiftUI

import FoodDataTypes

struct MicroPicker: View {
    
    @Environment(\.dismiss) var dismiss

    @Environment(FoodModel.self) var foodModel: FoodModel

    @State var selectedMicros: [Micro] = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(foodModel.availableMicroGroupsToAdd, id: \.self) { group in
                    Section(group.name) {
                        ForEach(foodModel.availableMicros(in: group), id: \.self) { micro in
                            cell(for: micro)
                        }
                    }
                }
            }
            .toolbar { toolbarContent }
            .navigationTitle("Micronutrients")
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame(idealWidth: 400, idealHeight: 800)
    }
    
    func cell(for micro: Micro) -> some View {
        var isSelected: Bool {
            selectedMicros.contains(micro)
        }
        
        return Button {
            if isSelected {
                selectedMicros.removeAll(where: { $0 == micro})
            } else {
                selectedMicros.append(micro)
            }
        } label: {
            HStack {
                Image(systemName: "checkmark")
                    .opacity(isSelected ? 1 : 0)
                Text(micro.name)
                    .foregroundStyle(Color(.label))
            }
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        foodModel.add(selectedMicros)
                        foodModel.setSaveDisabled()
                    }
                    dismiss()
                } label: {
                    Text("Add")
                        .fontWeight(.bold)
                }
                .disabled(selectedMicros.isEmpty)
            }
        }
    }
}
