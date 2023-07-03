import SwiftUI
//import SwiftData
import OSLog

import SwiftHaptics

let FoodsPageSize: Int = 100

struct FoodsView: View {
    
//    @Environment(\.modelContext) var context: ModelContext
    
    var foods: [Food] = []
    
    @State var showingFoodForm = false
    
    @State var hasAppeared = false
    
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
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.snappy) {
                hasAppeared = true
            }
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
            ForEach(foods, id: \.self) { food in
                FoodsViewCell(food: food)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Spacer().frame(height: HeroButton.bottom + HeroButton.size)
        }
        .listStyle(.plain)
    }
}

extension FoodsView {
    
    var buttonLayer: some View {
        func button(_ systemImage: String, action: @escaping () -> ()) -> some View {
            var label: some View {
                ZStack {
                    Circle()
                        .foregroundStyle(Color.accentColor.gradient)
                        .shadow(color: Color(.black).opacity(0.1), radius: 5, x: 0, y: 3)
                    Image(systemName: systemImage)
                        .font(.system(size: 25))
                        .fontWeight(.medium)
                        .foregroundStyle(Color(.systemBackground))
                }
                .frame(width: HeroButton.size, height: HeroButton.size)
                .hoverEffect(.lift)
            }
            
            var button: some View {
                Button {
                    Haptics.selectionFeedback()
                    action()
                } label: {
                    label
                }
            }
            
            return ZStack {
                label
                button
            }
        }
        
        var newFoodButton: some View {
            button("plus") {
                Haptics.selectionFeedback()
                showingFoodForm = true
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
