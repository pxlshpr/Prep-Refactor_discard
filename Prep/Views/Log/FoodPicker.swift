import SwiftUI
import OSLog

import SwiftSugar
import SwiftHaptics

struct FoodPicker: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var showingFoodForm: Bool = false

    @State var searchText: String = ""
    @State var searchIsActive: Bool = false

    @State var showingItem: Bool = false

    @State var model = FoodPickerModel.shared

    @Binding var isPresented: Bool
    @State var hasAppeared = false
    
    let meal: Meal?
    
    init(
        isPresented: Binding<Bool>,
        meal: Meal? = nil
    ) {
        _isPresented = isPresented
        self.meal = meal
    }
    
    var body: some View {
        NavigationStack {
            content
        }
        .onDisappear(perform: disappeared)
        .onAppear(perform: appeared)
        .frame(idealWidth: 400, idealHeight: 800)
        .presentationDetents([.medium, .fraction(0.90)])
    }
    
    var content: some View {
        Group {
            if hasAppeared {
                list
            }
        }
        .navigationTitle("Pick a Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .searchable(text: $searchText, isPresented: $searchIsActive, placement: .toolbar)
//        .searchable(text: $searchText, placement: .navigationBarDrawer)
    }
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.snappy) {
                hasAppeared = true
            }
        }
    }
    
    func disappeared() {
        model.reset()
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    if !searchIsActive && searchText.isEmpty {
                        Button {
                            searchIsActive = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    Button {
                        
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button {
                    showingFoodForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .popover(isPresented: $showingFoodForm) { foodForm }
            }
            ToolbarItemGroup(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    var foodForm: some View {
        EmptyView()
//        FoodForm()
    }
    
    var list: some View {
        List {
            ForEach(model.foodResults, id: \.self) { food in
                NavigationLink {
                    ItemForm(
                        isPresented: $isPresented,
                        meal: meal,
                        food: food
                    )
                } label: {
                    FoodCell(food: food)
                }
            }
        }
        .listStyle(.plain)
        .onChange(of: searchText, searchTextChanged)
    }
    
    func searchTextChanged(oldValue: String, newValue: String) {
        model.search(newValue)
    }
    
    enum Route: Hashable {
        case itemForm
    }
}
