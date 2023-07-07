import SwiftUI
import OSLog

import SwiftHaptics

struct FoodsView: View {

//    @Environment(FoodModel.self) var foodModel: FoodModel
    @State var foodModel = FoodModel()

//    let model = FoodsModel.shared
    @State var model = FoodsModel()

    @State var showingFoodForm = false
    @State var foodBeingEdited: Food? = nil

    @State var hasAppeared = false

    let didPopulate = NotificationCenter.default.publisher(for: .didPopulate)
    let didAddFood = NotificationCenter.default.publisher(for: .didAddFood)

    var body: some View {
        NavigationStack {
            content
                .onAppear(perform: appeared)
                .navigationTitle("My Foods")
        }
        .onReceive(didPopulate, perform: didPopulate)
        .onReceive(didAddFood, perform: didAddFood)
    }

    func didAddFood(notification: Notification) {
        guard let food = notification.userInfo?[Notification.PrepKeys.food] as? Food else {
            return
        }
        model.insertNewFood(food)
    }
    
    func didPopulate(notification: Notification) {
        model.loadMoreContentIfNeeded()
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
                Button {
                    Haptics.selectionFeedback()
                    foodModel.reset(for: food)
                    foodBeingEdited = food
//                    showingFoodForm = true
                } label: {
                    FoodCell(food: food)
                }
//                FoodsViewCell(food: food)
                .popover(item: editedFoodBinding(for: food), attachmentAnchor: CellPopoverAnchor) { food in
                    FoodForm(model: foodModel)
                }
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
    
    var buttonLayer: some View {
        var newFoodButton: some View {
            Menu {
                ForEach(FoodType.allCases) { foodType in
                    Button {
                        Haptics.selectionFeedback()
                        foodModel.reset()
                        showingFoodForm = true
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
                    .popover(isPresented: $showingFoodForm) { newFoodForm }
//                    .popover(item: $foodBeingEdited ) {
//                        FoodForm($0)
//                    }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, HeroButton.bottom)
        }
        .ignoresSafeArea(.keyboard)
    }
    
    func editedFoodBinding(for food: Food) -> Binding<Food?> {
        Binding<Food?>(
            get: {
                if let foodBeingEdited, food.id == foodBeingEdited.id {
                    return foodBeingEdited
                } else {
                    return nil
                }
            },
            set: { self.foodBeingEdited = $0 }
        )
    }
    
    var newFoodForm: some View {
        FoodForm(model: foodModel)
    }
}
