import Foundation
//import SwiftData
import OSLog

private let logger = Logger(subsystem: "FoodItemStore", category: "")

enum FoodItemStoreError: Error {
    case couldNotFindFood
    case couldNotFindMeal
}

//actor FoodItemStore: ModelActor {
//
//    static let shared = FoodItemStore()
//    
//    let executor: any ModelExecutor
//    init() {
//        let container = try! ModelContainer(for: allModelTypes)
//        let context = ModelContext(container)
//        let executor = DefaultModelExecutor(context: context)
//        self.executor = executor
//    }
//    
//    func create(foodItem: FoodItem) throws -> FoodItem {
//
//        let foodID = foodItem.food.id
//        let foodDescriptor = FetchDescriptor<FoodEntity>(predicate: #Predicate {
//            $0.uuid == foodID
//        })
//        guard let foodEntity = try context.fetch(foodDescriptor).first else {
//            throw FoodItemStoreError.couldNotFindFood
//        }
//        
//        let mealEntity: MealEntity?
//        if let mealID = foodItem.mealID {
//            let mealDescriptor = FetchDescriptor<MealEntity>(predicate: #Predicate {
//                $0.uuid == mealID
//            })
//            guard let fetched = try context.fetch(mealDescriptor).first else {
//                logger.error("Could not find meal with id: \(mealID, privacy: .public)")
//                throw FoodItemStoreError.couldNotFindMeal
//            }
//            mealEntity = fetched
//        } else {
//            mealEntity = nil
//        }
//        
//        let foodItemEntity = FoodItemEntity(
//            uuid: foodItem.id,
//            foodEntity: foodEntity,
//            mealEntity: mealEntity,
//            amount: foodItem.amount,
//            markedAsEatenAt: foodItem.markedAsEatenDate?.timeIntervalSince1970,
//            sortPosition: foodItem.sortPosition,
//            updatedAt: foodItem.updatedDate.timeIntervalSince1970,
//            badgeWidth: foodItem.badgeWidth
//        )
//        
//        context.insert(foodItemEntity)
//        try context.save()
//        return FoodItem(
//            foodItemEntity,
//            foodEntity: foodEntity
//        )
//    }
//    
//    static func create(foodItem: FoodItem) {
//        Task {
//            do {
//                let foodItem = try await shared.create(foodItem: foodItem)
//                await MainActor.run {
//                    post(.didAddFoodItem, userInfo: [.foodItem: foodItem])
//                }
//            } catch {
//                logger.error("Error creating foodItem: \(error, privacy: .public)")
//            }
//        }
//    }
//}
