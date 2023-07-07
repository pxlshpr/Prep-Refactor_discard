import SwiftUI
import OSLog

import SwiftHaptics

struct FoodsView: View {
    
    @State var showingFoodForm = false
    @State var hasAppeared = false
    
    let model = FoodsModel.shared
    
    init() {
//        let predicate = #Predicate<FoodEntity> {
//            $0.datasetValue == nil
//        }
//        
//        let sortDescriptors: [SortDescriptor<FoodEntity>] = [
//            SortDescriptor(\.name),
//            SortDescriptor(\.detail),
//            SortDescriptor(\.brand)
//        ]
//        
//        let descriptor = FetchDescriptor<FoodEntity>(
//            predicate: predicate,
//            sortBy: sortDescriptors
//        )
//        _foods = Query(descriptor)
    }
    
    var body: some View {
        NavigationStack {
            content
                .onAppear(perform: appeared)
                .navigationTitle("My Foods")
        }
    }
   
    
    var content: some View {
        ZStack {
            if hasAppeared {
                list
            }
            buttonLayer
        }
    }

    var list: some View {
        List {
            ForEach(model.foods, id: \.self) { food in
                FoodsViewCell(food: food)
                    .onAppear {
                        model.loadMoreContentIfNeeded(currentFood: food)
                    }
            }
            if model.isLoadingPage {
                ProgressView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            Spacer().frame(height: HeroButton.bottom + HeroButton.size)
        }
        .listStyle(.plain)
    }
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.snappy) {
                hasAppeared = true
            }
        }
    }
}

extension FoodsView {
    
    var buttonLayer: some View {
        var newFoodButton: some View {
            Menu {
                ForEach(FoodType.allCases) { foodType in
                    Button {
                        Haptics.selectionFeedback()
                    } label: {
                        Label(foodType.description, systemImage: foodType.systemImage)
                    }
                }
            } label: {
                heroButtonLabel("plus")
            }
        }
        
        return VStack {
            Spacer()
            HStack(alignment: .bottom) {
                Spacer()
                newFoodButton
                    .popover(isPresented: $showingFoodForm) { foodForm }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, HeroButton.bottom)
        }
        .ignoresSafeArea(.keyboard)
    }
    
    var foodForm: some View {
        FoodForm()
    }
}
