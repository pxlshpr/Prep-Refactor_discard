import Foundation
import CoreData

extension DayEntity2 {
    
    convenience init(
        context: NSManagedObjectContext,
        dateString: String
    ) {
        self.init(context: context)
        self.dateString = dateString
    }
}
