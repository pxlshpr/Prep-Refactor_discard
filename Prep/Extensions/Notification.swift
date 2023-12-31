import Foundation

extension Notification.Name {

    static var didTapToday: Notification.Name { return .init("didTapToday") }

    static var didPopulate: Notification.Name { return .init("didPopulate") }

    static var didPickMeal: Notification.Name { return .init("didPickMeal") }
    static var didModifyMeal: Notification.Name { return .init("didModifyMeal") }
//    static var didUpdateMeal: Notification.Name { return .init("didUpdateMeal") }
//    static var didDeleteMeal: Notification.Name { return .init("didDeleteMeal") }
    static var didAddFood: Notification.Name { return .init("didAddFood") }
    static var didUpdateFood: Notification.Name { return .init("didUpdateFood") }

    static var didAddFoodItem: Notification.Name { return .init("didAddFoodItem") }
    static var didDeleteFoodItem: Notification.Name { return .init("didDeleteFoodItem") }

    static var safeAreaDidChange: Notification.Name { return .init("safeAreaDidChange") }
}

extension Notification {
    enum PrepKeys: String {
        case day = "day"
        case meal = "meal"
        case food = "food"
        case foodItem = "foodItem"
        case safeArea = "safeArea"
    }
}

func post(_ name: Notification.Name, userInfo: [Notification.PrepKeys : Any]? = nil) {
    NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
}
