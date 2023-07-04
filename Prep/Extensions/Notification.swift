import Foundation

extension Notification.Name {

    static var didPopulate: Notification.Name { return .init("didPopulate") }

    static var didPickMeal: Notification.Name { return .init("didPickMeal") }
    static var didDeleteMeal: Notification.Name { return .init("didDeleteMeal") }
    static var didAddMeal: Notification.Name { return .init("didAddMeal") }
    
    static var didUpdateMeal: Notification.Name { return .init("didUpdateMeal") }
    static var didAddFoodItem: Notification.Name { return .init("didAddFoodItem") }

    static var safeAreaDidChange: Notification.Name { return .init("safeAreaDidChange") }
}

extension Notification {
    enum PrepKeys: String {
        case day = "day"
        case meal = "meal"
        case foodItem = "foodItem"
        case safeArea = "safeArea"
    }
}

func post(_ name: Notification.Name, userInfo: [Notification.PrepKeys : Any]? = nil) {
    NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
}
