import SwiftUI

struct FoodImageViewer: View {
    
    @Environment(\.dismiss) var dismiss
    @Bindable var foodModel: FoodModel
    
    init(_ foodModel: FoodModel) {
        self.foodModel = foodModel
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                tabView
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }
    
    
    var tabView: some View {
        TabView(selection: $foodModel.presentedImageIndex) {
            ForEach(foodModel.images.indices, id: \.self) { index in
                Image(uiImage: foodModel.images[index])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
    
    var title: String {
        "Image \(foodModel.presentedImageIndex + 1) of \(foodModel.images.count)"
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
    }
}
