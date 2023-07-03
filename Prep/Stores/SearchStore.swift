import Foundation
import CoreData
import OSLog

private let logger = Logger(subsystem: "Search", category: "SearchStore")
private let NumberOfRecents = 100
private let NumberOfSearchResults = 500

class SearchStore {

    static let shared = SearchStore()
    
    static func recents() async -> [Food] {
        logger.debug("Fetching recents")
        let start = CFAbsoluteTimeGetCurrent()
        let results = await DataManager.shared.recents()
        logger.debug("Fetched \(results.count) recents in: \(CFAbsoluteTimeGetCurrent()-start)s")
        return results
    }

//    func foods(page: Int) throws -> [FoodResult] {
//        
//        let start = CFAbsoluteTimeGetCurrent()
//        let limit = FoodsPageSize
//        let offset = max((page - 1) * FoodsPageSize, 0)
////        let limit = page == 1 ? FoodsPageSize : 0
////        let offset = max((page - 1) * FoodsPageSize, 0)
////        let limit = 100
////        let offset = 300
//        
//        logger.notice("Fetching page \(page) of Foods with fetchLimit: \(limit) and fetchOffset: \(offset)")
//
//        var descriptor = FetchDescriptor<FoodEntity>(
//            sortBy: [
//                SortDescriptor(\.name, order: .forward),
//                SortDescriptor(\.detail, order: .forward),
//                SortDescriptor(\.brand, order: .forward)
//            ]
//        )
//        descriptor.fetchOffset = offset
//        descriptor.fetchLimit = limit
//        
//        let results: [FoodResult] = try context
//            .fetch(descriptor)
//            .map { FoodResult($0) }
//        
//        logger.notice("Fetched \(results.count) Foods in: \(CFAbsoluteTimeGetCurrent()-start)s")
//        return Array(results)
//    }
//
    static func search(_ text: String) async -> [Food] {
        
        guard !text.isEmpty else {
            return await recents()
        }
        var start = CFAbsoluteTimeGetCurrent()
        logger.debug("Fetching foods matching '\(text, privacy: .public)'")

        var results = await DataManager.shared.foods(matching: text)
        
        logger.debug("Fetched \(results.count) foods in: \(CFAbsoluteTimeGetCurrent()-start)s")

        start = CFAbsoluteTimeGetCurrent()
        results.sort(by: {
            
            let distance0 = $0.distanceOfSearchText(text)
            let distance1 = $1.distanceOfSearchText(text)
            
            /// When distance of search text within food is equal
            if distance0 == distance1 {
                /// Check the total length of the name, brand and detail fields
                let count0 = $0.totalCount
                let count1 = $1.totalCount

                /// When length of results are also equal
                if count0 == count1 {
                    
                    /// Check the ratio of the text within the relevant field's text
                    let ratio0 = $0.ratioOfSearchText(text)
                    let ratio1 = $1.ratioOfSearchText(text)

//                    /// When ratio is also equal
//                    if ratio0 == ratio1 {
//                        /// *Prioritise the latest used foods*
//                        return $0.lastUsedAt > $1.lastUsedAt
//                    }

                    /// *Prioritise foods that have a higher ratio of the search term within the matching field*
                    return ratio0 > ratio1
                }
                
                /// *Prioritise the shorter results*
                return count0 < count1
            }
                
            /// *Prioritise foods that the search term closer to the start of the matching field*
            return distance0 < distance1
        })
        
        logger.debug("Sorted in: \(CFAbsoluteTimeGetCurrent()-start)s")

        return results
    }
}

extension DataManager {
    func recents() async -> [Food] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.recents { recents in
                        let results = recents.map { Food($0) }
                        continuation.resume(returning: results)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error getting recents: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
    func foods(matching text: String) async -> [Food] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.foods(matching: text) { foods in
                        let results = foods.map { Food($0) }
                        continuation.resume(returning: results)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("Error getting recents: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
}

extension CoreDataManager {
    
    func foods(matching text: String, completion: @escaping (([FoodEntity]) -> ())) throws {
        Task {
            let bgContext =  newBackgroundContext()
            await bgContext.perform {
                do {
                    let request: NSFetchRequest<FoodEntity> = FoodEntity.fetchRequest()
                    
                    let name = NSPredicate(format: "name CONTAINS[cd] %@", text)
                    let detail = NSPredicate(format: "detail CONTAINS[cd] %@", text)
                    let brand = NSPredicate(format: "brand CONTAINS[cd] %@", text)
                    let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                        name, detail, brand
                    ])
                    
                    request.predicate = predicate
                    request.fetchLimit = NumberOfSearchResults
                    let entities = try bgContext.fetch(request)
                    completion(entities)
                } catch {
                    logger.error("Error: \(error.localizedDescription, privacy: .public)")
                    completion([])
                }
            }
        }
    }
    
    func recents(completion: @escaping (([FoodEntity]) -> ())) throws {
        Task {
            let bgContext =  newBackgroundContext()
            await bgContext.perform {
                do {
                    let request: NSFetchRequest<FoodEntity> = FoodEntity.fetchRequest()
                    request.sortDescriptors = [
                        NSSortDescriptor(key: "lastUsedAt", ascending: false)
                    ]
                    request.fetchLimit = NumberOfRecents
                    let entities = try bgContext.fetch(request)
                    completion(entities)
                } catch {
                    logger.error("Error: \(error.localizedDescription, privacy: .public)")
                    completion([])
                }
            }
        }
    }
}
