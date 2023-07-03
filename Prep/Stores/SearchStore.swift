//import Foundation
//import SwiftData
//import OSLog
//
//actor SearchStore: ModelActor {
//
//    let logger = Logger(subsystem: "Search", category: "SearchStore")
//
//    static let shared = SearchStore()
//    
//    let NumberOfRecents = 100
//    
//    let executor: any ModelExecutor
//    init() {
//        let container = try! ModelContainer(for: allModelTypes)
//        let context = ModelContext(container)
//        let executor = DefaultModelExecutor(context: context)
//        self.executor = executor
//    }
//    
//    func recents() throws -> [FoodResult] {
//        
//        let start = CFAbsoluteTimeGetCurrent()
//        
//        logger.debug("Fetching recents")
//
//        var descriptor = FetchDescriptor<FoodEntity>(
//            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
//        )
//        descriptor.fetchLimit = NumberOfRecents
//        let results: [FoodResult] = try context.fetch(descriptor)
//            .map { FoodResult($0) }
//        
//        logger.debug("Fetched \(results.count) recents in: \(CFAbsoluteTimeGetCurrent()-start)s")
//        
//        return Array(results.prefix(NumberOfRecents))
//    }
//
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
//    func search(_ text: String) throws -> [FoodResult] {
//        
//        guard !text.isEmpty else {
//            return try recents()
//        }
//        
//        var descriptor: FetchDescriptor<FoodEntity> {
//
//            let lowercased = text.lowercased()
//            let predicate: Predicate<FoodEntity> = #Predicate {
//                $0.lowercasedName.contains(lowercased)
//                || $0.lowercasedDetail.contains(lowercased)
//                || $0.lowercasedBrand.contains(lowercased)
//            }
//            var descriptor = FetchDescriptor(predicate: predicate)
//            descriptor.fetchLimit = 100
//            return descriptor
//        }
//        
//        var start = CFAbsoluteTimeGetCurrent()
//        logger.debug("Fetching foods matching '\(text, privacy: .public)'")
//
//        var results = try context.fetch(descriptor).map { FoodResult($0) }
//        
//        logger.debug("Fetched \(results.count) foods in: \(CFAbsoluteTimeGetCurrent()-start)s")
//
//        start = CFAbsoluteTimeGetCurrent()
//        results.sort(by: {
//            
//            let distance0 = $0.distanceOfSearchText(text)
//            let distance1 = $1.distanceOfSearchText(text)
//            
//            if distance0 == distance1 {
//                /// When distance of search text within food is equal, prioritise the most recently used
//                return $0.lastUsedAt > $1.lastUsedAt
//            }
//                
//            return distance0 < distance1
//        })
//        
//        logger.debug("Sorted in: \(CFAbsoluteTimeGetCurrent()-start)s")
//
//        
//        return results
//    }
//}
