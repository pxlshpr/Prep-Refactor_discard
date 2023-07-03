import Foundation

enum Tab: Hashable {
    case log
    case nutrition
    case goals
    case foods
    case settings
}

extension Tab {
    var title: String {
        switch self {
        case .log:
            return "Log"
        case .nutrition:
            return "Nutrition"
        case .goals:
            return "Goals"
        case .foods:
            return "My Foods"
        case .settings:
            return "Settings"
        }
    }
    
    var systemImage: String {
        switch self {
        case .log:
            return "book.closed"
        case .nutrition:
            return "chart.bar.doc.horizontal"
        case .goals:
            return "target"
        case .foods:
            return "carrot"
        case .settings:
            return "gearshape"
        }
    }
}
