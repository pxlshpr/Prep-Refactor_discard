import Foundation

extension Notification.Name {
    
    static var didPickMeal: Notification.Name { return .init("didPickMeal") }
    static var didDeleteMeal: Notification.Name { return .init("didDeleteMeal") }
    static var didAddFoodItem: Notification.Name { return .init("didAddFoodItem") }
    static var didAddMeal: Notification.Name { return .init("didAddMeal") }
    
}

extension Notification {
    enum PrepKeys: String {
        case meal = "meal"
        case foodItem = "foodItem"
    }
}

func post(_ name: Notification.Name, userInfo: [Notification.PrepKeys : Any]? = nil) {
    NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
}
