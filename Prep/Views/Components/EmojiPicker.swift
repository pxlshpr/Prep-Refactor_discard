import SwiftUI
import OSLog

import SwiftHaptics
import FormSugar
import ViewSugar

let emojiPickerLogger = Logger(subsystem: "EmojiPicker", category: "")

struct EmojiPicker: View {
    
    @Environment(\.dismiss) var dismiss
    @State var searchIsFocused = false
    @State var model: EmojiPickerModel

    @State var searchIsActive: Bool = false
    @State var hasAppeared = false

    let didTapEmoji: ((String) -> Void)
    let focusOnAppear: Bool
    let includeCancelButton: Bool
    let includeClearButton: Bool
    let size: EmojiSize
    @Binding var recents: [String]

    enum EmojiSize {
        case large
        case small
        
        var fontSize: CGFloat {
            switch self {
            case .large: return 50
            case .small: return 30
            }
        }

        var columnSize: CGFloat {
            fontSize + spacing
        }

        var spacing: CGFloat {
            switch self {
            case .large: return 20
            case .small: return 5
            }
        }
        
        var sectionSpacing: CGFloat {
            switch self {
            case .large: return 0
            case .small: return 20
            }
        }
    }
    
    init(
        recents: Binding<[String]> = .constant([]),
        size: EmojiSize = .small,
        categories: [EmojiCategory]? = nil,
        focusOnAppear: Bool = false,
        includeCancelButton: Bool = false,
        includeClearButton: Bool = false,
        didTapEmoji: @escaping ((String) -> Void)
    ) {
        let model = EmojiPickerModel(categories: categories, recents: recents.wrappedValue)
        _model = State(initialValue: model)
        _recents = recents
        self.size = size
        self.didTapEmoji = didTapEmoji
        self.focusOnAppear = focusOnAppear
        self.includeClearButton = includeClearButton
        self.includeCancelButton = includeCancelButton
    }
    
    var body: some View {
        Group {
            if hasAppeared {
                scrollView
                    .searchable(text: $model.searchText, isPresented: $searchIsActive, placement: .toolbar)
            } else {
                Color.clear
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.snappy) {
                                hasAppeared = true
                            }
                        }
                    }
            }
        }
        .navigationTitle("Choose Emoji")
        .toolbar { trailingContent }
        .toolbar { bottomContent }
        .onChange(of: recents) { oldValue, newValue in
            model.initialRecents = newValue
            model.updateData()
        }
    }
    
    var bottomContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                searchIsActive = true
            } label: {
                Image(systemName: "magnifyingglass")
            }
        }
    }
    
    var scrollView: some View {
        ScrollView {
            if !model.recents.isEmpty {
                recentsGrid
            }
            grid
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if includeClearButton {
                Button {
                    Haptics.feedback(style: .soft)
                    didTapEmoji("")
                } label: {
                    Text("Clear")
                }
            }
        }
    }
    
    var grid: some View {
        
        func isFirst(_ index: Int) -> Bool {
            guard model.recents.isEmpty else { return false }
            return model.gridData.firstIndex(where: { !$0.emojis.isEmpty }) == index
        }

        var columns: [GridItem] {
            [GridItem(.adaptive(minimum: size.columnSize))]
        }

        return LazyVGrid(columns: columns, spacing: size.spacing) {
            ForEach(model.gridData.indices, id: \.self) { i in
                if !model.gridData[i].emojis.isEmpty {
                    section(for: model.gridData[i], isFirst: isFirst(i))
                }
            }
        }
        .padding(.horizontal)
    }

    var recentsGrid: some View {

        var header: some View {
            Text("Recents")
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        var columns: [GridItem] {
            [GridItem(.adaptive(minimum: 50))]
        }

        return LazyVGrid(columns: columns, spacing: 10) {
            Section(header: header) {
                ForEach(model.recents, id: \.self) { emoji in
                    button(for: emoji, fontSize: 50)
                }
            }
        }
        .padding(.horizontal)
    }
    
    func section(for gridSection: EmojiPickerModel.GridSection, isFirst: Bool = false) -> some View {
        
        
        @ViewBuilder
        var header: some View {
            if model.gridData.count > 1 {
                Text(gridSection.category)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .if(!isFirst, transform: { view in
                        view
                            .padding(.top, size.sectionSpacing)
                    })
            } else {
                EmptyView()
            }
        }
        
        return Section(header: header) {
            ForEach(gridSection.emojis, id: \.self) { emoji in
                button(for: emoji.emoji)
            }
        }
    }
    
    func button(for emoji: String, fontSize: CGFloat? = nil) -> some View {
        Text(emoji)
            .font(.system(size: fontSize ?? size.fontSize))
            .onTapGesture {
                didTapEmoji(emoji)
            }
    }
}

//MARK: - EmojiPickerModel

import Observation

@Observable class EmojiPickerModel {
    
    typealias GridSection = (category: String, emojis: [EmojiWithCategory])
    typealias GridData = [GridSection]

    var searchText = "" {
        didSet {
            updateData()
        }
    }
    var categories: [EmojiCategory]? = nil
    var gridData: GridData = []

    var initialRecents: [String] = []
    var recents: [String] = []

    var emojis: Emojis = Emojis(categories: [])

    var emojiGroups: [EmojisFileGroup] = []
    
    var keywords: [String: [String]] = [:]

    init(categories: [EmojiCategory]?, recents: [String]) {
        self.categories = categories
        self.initialRecents = recents
        self.recents = []
        loadEmojisFromFile()
    }

    func loadEmojisFromFile() {
        Task {
            do {
                
                guard let emojisPath = Bundle.main.path(
                    forResource: "emojis-by-group",
                    ofType: "json")
                else { return }
                
                let emojisData = try Data(
                    contentsOf: URL(fileURLWithPath: emojisPath),
                    options: .mappedIfSafe
                )
                self.emojiGroups = try JSONDecoder().decode(
                    [EmojisFileGroup].self,
                    from: emojisData
                )

                guard let keywordsPath = Bundle.main.path(
                    forResource: "emoji-keywords",
                    ofType: "json")
                else { return }
                
                let keywordsData = try Data(
                    contentsOf: URL(fileURLWithPath: keywordsPath),
                    options: .mappedIfSafe
                )
                self.keywords = try JSONDecoder().decode(
                    [String : [String]].self,
                    from: keywordsData
                )
                
                await MainActor.run {
                    updateData()
                }
            } catch {
                emojiPickerLogger.error("Error: \(error, privacy: .public)")
            }
        }
    }
    
    func updateData() {
        let categories = categories ?? EmojiCategory.allCases

        gridData = emojiGroups.gridData(
            for: categories,
            searchText: searchText,
            allKeywords: keywords
        )
        recents = emojiGroups.recentStrings(
            for: initialRecents,
            searchText: searchText,
            allKeywords: keywords
        )
    }
}

//MARK: - EmojiWithCategory

struct EmojiWithCategory: Identifiable, Hashable, Equatable {
    let category: EmojiCategory?
    let emoji: String
    
    init(category: EmojiCategory? = nil, emoji: String) {
        self.category = category
        self.emoji = emoji
    }
    
    var id: String {
        "\(category?.description ?? "recents")-\(emoji)"
    }
}

//MARK: - EmojiCategory

enum EmojiCategory: String, Equatable, CaseIterable {
    case smileysAndPeople
    case animalsAndNature
    case foodAndDrink
    case activity
    case travelAndPlaces
    case objects
    case symbols
    case flags
    
    var description: String {
        switch self {
        case .smileysAndPeople:
            return "Smileys & People"
        case .animalsAndNature:
            return "Animals & Nature"
        case .foodAndDrink:
            return "Food & Drink"
        case .activity:
            return "Activity"
        case .travelAndPlaces:
            return "Travel & Places"
        case .objects:
            return "Objects"
        case .symbols:
            return "Symbols"
        case .flags:
            return "Flags"
        }
    }
    
    var emojisFileDescriptions: [String] {
        switch self {
        case .smileysAndPeople:
            return ["Smileys & Emotion", "People & Body"]
        case .animalsAndNature:
            return ["Animals & Nature"]
        case .foodAndDrink:
            return ["Food & Drink"]
        case .activity:
            return ["Activities"]
        case .travelAndPlaces:
            return ["Travel & Places"]
        case .objects:
            return ["Objects"]
        case .symbols:
            return ["Symbols"]
        case .flags:
            return ["Flags"]
        }
    }
}

//MARK: - Emojis+GridData

extension Emojis {
    func gridData(for filteredCategories: [EmojiCategory], searchText: String) -> EmojiPickerModel.GridData {
        var gridData = EmojiPickerModel.GridData()
        for filteredCategory in filteredCategories {
            guard let category = categories.first(where: { $0.name == filteredCategory.rawValue }),
                  !category.emojis.isEmpty else {
                continue
            }
            
            let emojis: [Emoji]
            if searchText.isEmpty {
                emojis = category.emojis
            } else {
                emojis = category.emojis.filter({
                    //TODO: use regex to match start of words only and do other heuristics
                    $0.name.contains(searchText.lowercased())
                    ||
                    $0.keywords.contains(searchText.lowercased())
                })
            }
            
            gridData.append(EmojiPickerModel.GridSection(
                category: filteredCategory.description,
                emojis: emojis.map {
                    EmojiWithCategory(
                        category: filteredCategory,
                        emoji: $0.emoji
                    )
                }
            ))
        }
        return gridData
    }
    
    func recentStrings(for recents: [String], searchText: String) -> [String] {
        recents.compactMap {
            self.emoji(matching: $0)
        }
        .filter({
            guard !searchText.isEmpty else {
                return true
            }
            //TODO: use regex to match start of words only and do other heuristics
            return $0.name.contains(searchText.lowercased())
            ||
            $0.keywords.contains(searchText.lowercased())
        })
        .map { $0.emoji }
    }
}

extension Array where Element == EmojisFileGroup {
    
    func gridData(
        for filteredCategories: [EmojiCategory],
        searchText: String,
        allKeywords: [String : [String]]
    ) -> EmojiPickerModel.GridData {
        
        var gridData = EmojiPickerModel.GridData()
        for filteredCategory in filteredCategories {
            
            /// Get the categories matching
            let categories = self.filter({
                filteredCategory.emojisFileDescriptions.contains($0.name)
                && !$0.emojis.isEmpty
            })
            
            guard !categories.isEmpty else { continue }
            
            let emojis: [EmojisFileEmoji]
            if searchText.isEmpty {
                emojis = categories.reduce([]) { $0 + $1.emojis }
            } else {
                
                let allEmojis = categories.reduce([]) { $0 + $1.emojis }
                
                let string = searchText.lowercased()
                emojis = allEmojis.filter({ emoji in
                    
                    let keywords = allKeywords[emoji.emoji] ?? []
                    
                    //TODO: use regex to match start of words only and do other heuristics
                    let bool = emoji.name.lowercased().contains(string)
                    ||
                    keywords.contains(where: { $0.contains(string) })
                    
                    if bool {
                        emojiPickerLogger.debug("\(emoji.emoji): \(keywords.joined(separator: ";"))")
                    }
                    
                    return bool
                })
            }
            
            gridData.append(EmojiPickerModel.GridSection(
                category: filteredCategory.description,
                emojis: emojis.map {
                    EmojiWithCategory(
                        category: filteredCategory,
                        emoji: $0.emoji
                    )
                }
            ))
        }
        return gridData
    }
    
    func emoji(_ string: String) -> EmojisFileEmoji? {
        for group in self {
            for emoji in group.emojis {
                if emoji.emoji == string {
                    return emoji
                }
            }
        }
        return nil
    }
    
    func recentStrings(
        for recents: [String],
        searchText: String,
        allKeywords: [String : [String]]
    ) -> [String] {
        recents.compactMap {
            self.emoji($0)
        }
        .filter({ emoji in
            guard !searchText.isEmpty else {
                return true
            }
            
            let string = searchText.lowercased()
            let keywords = allKeywords[emoji.emoji] ?? []
            
            //TODO: use regex to match start of words only and do other heuristics
            let bool = emoji.name.lowercased().contains(string)
            ||
            keywords.contains(where: { $0.contains(string) })
            
            if bool {
                emojiPickerLogger.debug("\(emoji.emoji): \(keywords.joined(separator: ";"))")
            }

            return bool
        })
        .map { $0.emoji }
    }
}

//MARK: - Structs

import Foundation

struct EmojisFileGroup: Codable {
    let name: String
    let slug: String
    let emojis: [EmojisFileEmoji]
}

struct EmojisFileEmoji: Codable {
    let emoji: String
    let skin_tone_support: Bool
    let name: String
    let slug: String
    let unicode_version: String
    let emoji_version: String
}

//MARK: - Legacy

struct Emojis: Codable {
    let categories: [Category]
    
    func emoji(matching string: String) -> Emoji? {
        for category in categories {
            for emoji in category.emojis {
                if emoji.emoji == string {
                    return emoji
                }
            }
        }
        return nil
    }
}

struct Category: Codable {
    let name: String
    let emojis: [Emoji]
}

struct Emoji: Codable {
    let emoji: String
    let name: String
    let keywords: String
}

