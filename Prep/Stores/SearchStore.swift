import Foundation
import CoreData
import OSLog

private let logger = Logger(subsystem: "Search", category: "SearchStore")
private let NumberOfRecents = 100

class SearchStore {

    static let shared = SearchStore()
    
    static func recents() async -> [FoodResult] {
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
    static func search(_ text: String) async -> [FoodResult] {
        
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
            
            if distance0 == distance1 {
                /// When distance of search text within food is equal, prioritise the most recently used
                return $0.lastUsedAt > $1.lastUsedAt
            }
                
            return distance0 < distance1
        })
        
        logger.debug("Sorted in: \(CFAbsoluteTimeGetCurrent()-start)s")

        return results
    }
}

extension DataManager {
    func recents() async -> [FoodResult] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.recents { recents in
                        let results = recents.map { FoodResult($0) }
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
    func foods(matching text: String) async -> [FoodResult] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    try coreDataManager.foods(matching: text) { foods in
                        let results = foods.map { FoodResult($0) }
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
    
    func foods(matching text: String, completion: @escaping (([FoodEntity2]) -> ())) throws {
        Task {
            let bgContext =  newBackgroundContext()
            await bgContext.perform {
                do {
                    let request: NSFetchRequest<FoodEntity2> = FoodEntity2.fetchRequest()
                    
                    let name = NSPredicate(format: "name CONTAINS[cd] %@", text)
                    let detail = NSPredicate(format: "detail CONTAINS[cd] %@", text)
                    let brand = NSPredicate(format: "brand CONTAINS[cd] %@", text)
                    let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                        name, detail, brand
                    ])
                    
                    request.predicate = predicate
                    request.fetchLimit = 100
                    let entities = try bgContext.fetch(request)
                    completion(entities)
                } catch {
                    logger.error("Error: \(error.localizedDescription, privacy: .public)")
                    completion([])
                }
            }
        }
    }
    
    func recents(completion: @escaping (([FoodEntity2]) -> ())) throws {
        Task {
            let bgContext =  newBackgroundContext()
            await bgContext.perform {
                do {
                    let request: NSFetchRequest<FoodEntity2> = FoodEntity2.fetchRequest()
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
