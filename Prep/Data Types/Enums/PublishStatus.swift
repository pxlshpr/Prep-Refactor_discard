import Foundation

enum PublishStatus: Int, Codable {
    case hidden = 1
    case pendingReview
    case verified
    case rejected
}
