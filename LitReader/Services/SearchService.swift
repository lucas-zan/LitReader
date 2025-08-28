import Foundation
import SwiftUI
import Combine

// MARK: - Search Models
struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    let bookId: String
    let position: Int
    let context: String
    let snippet: String
    let page: Int?
    let relevance: Double
    let type: ResultType
    let title: String
    let bookTitle: String
    
    enum ResultType: String, CaseIterable {
        case book = "book"
        case content = "content"
        case bookmark = "bookmark"
    }
    
    init(bookId: String, position: Int, context: String, snippet: String, page: Int?, relevance: Double, type: ResultType = .content, title: String = "", bookTitle: String = "") {
        self.bookId = bookId
        self.position = position
        self.context = context
        self.snippet = snippet
        self.page = page
        self.relevance = relevance
        self.type = type
        self.title = title
        self.bookTitle = bookTitle
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.id == rhs.id
    }
}

struct SearchQuery {
    let text: String
    let useRegex: Bool
    let caseSensitive: Bool
    let wholeWords: Bool
    let bookIds: [String]?
    let searchInContent: Bool
    let searchInBookmarks: Bool
    let searchInMetadata: Bool
    
    init(text: String, useRegex: Bool = false, caseSensitive: Bool = false, wholeWords: Bool = false, bookIds: [String]? = nil, searchInContent: Bool = true, searchInBookmarks: Bool = true, searchInMetadata: Bool = true) {
        self.text = text
        self.useRegex = useRegex
        self.caseSensitive = caseSensitive
        self.wholeWords = wholeWords
        self.bookIds = bookIds
        self.searchInContent = searchInContent
        self.searchInBookmarks = searchInBookmarks
        self.searchInMetadata = searchInMetadata
    }
}

struct SearchHistoryItem: Identifiable, Codable {
    let id: UUID
    let query: String
    let timestamp: Date
    let resultCount: Int
    
    init(query: String, timestamp: Date = Date(), resultCount: Int) {
        self.id = UUID()
        self.query = query
        self.timestamp = timestamp
        self.resultCount = resultCount
    }
}

// MARK: - Search Service
@MainActor
class SearchService: ObservableObject {
    static let shared = SearchService()
    
    @Published var isSearching = false
    @Published var searchResults: [SearchResult] = []
    @Published var searchHistory: [SearchHistoryItem] = []
    @Published var currentQuery: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let maxHistoryItems = 50
    
    private init() {
        loadSearchHistory()
    }
    
    // MARK: - Main Search Function
    func search(query: SearchQuery) async -> [SearchResult] {
        guard !query.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        isSearching = true
        defer { isSearching = false }
        
        var results: [SearchResult] = []
        let dataManager = DataManager.shared
        
        // 确定要搜索的书籍
        let booksToSearch = query.bookIds != nil ? 
            dataManager.library.books.filter { query.bookIds!.contains($0.id) } :
            dataManager.library.books
        
        for book in booksToSearch {
            do {
                let bookResults = try await searchInBook(book: book, query: query)
                results.append(contentsOf: bookResults)
            } catch {
                print("搜索书籍 \(book.title) 时出错: \(error)")
            }
        }
        
        // 按相关性排序
        results.sort { $0.relevance > $1.relevance }
        
        // 更新搜索历史
        await addToHistory(query.text, resultCount: results.count)
        
        await MainActor.run {
            self.searchResults = results
            self.currentQuery = query.text
        }
        
        return results
    }
    
    // MARK: - Search in Book
    private func searchInBook(book: Book, query: SearchQuery) async throws -> [SearchResult] {
        let bookParser = BookParser.shared
        let content = try await bookParser.getFileContent(book.filePath)
        
        var results: [SearchResult] = []
        
        if query.useRegex {
            results = searchWithRegex(content: content, pattern: query.text, book: book)
        } else {
            results = searchWithText(content: content, query: query, book: book)
        }
        
        return results
    }
    
    // MARK: - Text Search
    private func searchWithText(content: String, query: SearchQuery, book: Book) -> [SearchResult] {
        var results: [SearchResult] = []
        let searchText = query.caseSensitive ? query.text : query.text.lowercased()
        // let searchContent = query.caseSensitive ? content : content.lowercased()
        
        let lines = content.components(separatedBy: .newlines)
        var currentPosition = 0
        
        for (_, line) in lines.enumerated() {
            let searchLine = query.caseSensitive ? line : line.lowercased()
            
            if query.wholeWords {
                // 全词匹配
                let words = searchLine.components(separatedBy: .whitespacesAndNewlines)
                if words.contains(searchText) {
                    let result = SearchResult(
                        bookId: book.id,
                        position: currentPosition,
                        context: line,
                        snippet: generateSnippet(line: line, searchText: query.text),
                        page: calculatePage(position: currentPosition, totalLength: content.count, totalPages: book.totalPages),
                        relevance: calculateRelevance(line: line, searchText: query.text),
                        type: .content,
                        title: line.trimmingCharacters(in: .whitespacesAndNewlines),
                        bookTitle: book.title
                    )
                    results.append(result)
                }
            } else {
                // 部分匹配
                if searchLine.contains(searchText) {
                    let result = SearchResult(
                        bookId: book.id,
                        position: currentPosition,
                        context: line,
                        snippet: generateSnippet(line: line, searchText: query.text),
                        page: calculatePage(position: currentPosition, totalLength: content.count, totalPages: book.totalPages),
                        relevance: calculateRelevance(line: line, searchText: query.text),
                        type: .content,
                        title: line.trimmingCharacters(in: .whitespacesAndNewlines),
                        bookTitle: book.title
                    )
                    results.append(result)
                }
            }
            
            currentPosition += line.count + 1 // +1 for newline
        }
        
        return results
    }
    
    // MARK: - Regex Search
    private func searchWithRegex(content: String, pattern: String, book: Book) -> [SearchResult] {
        var results: [SearchResult] = []
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: content.utf16.count)
            
            let matches = regex.matches(in: content, options: [], range: range)
            
            for match in matches {
                if let swiftRange = Range(match.range, in: content) {
                    let matchedText = String(content[swiftRange])
                    let context = getContextForMatch(content: content, range: swiftRange)
                    
                    let result = SearchResult(
                        bookId: book.id,
                        position: content.distance(from: content.startIndex, to: swiftRange.lowerBound),
                        context: context,
                        snippet: matchedText,
                        page: calculatePage(
                            position: content.distance(from: content.startIndex, to: swiftRange.lowerBound),
                            totalLength: content.count,
                            totalPages: book.totalPages
                        ),
                        relevance: 1.0, // 正则匹配都视为高相关性
                        type: .content,
                        title: matchedText,
                        bookTitle: book.title
                    )
                    results.append(result)
                }
            }
        } catch {
            print("正则表达式错误: \(error)")
        }
        
        return results
    }
    
    // MARK: - Helper Functions
    private func generateSnippet(line: String, searchText: String) -> String {
        let maxSnippetLength = 100
        let searchRange = line.range(of: searchText, options: .caseInsensitive)
        
        guard let range = searchRange else {
            return String(line.prefix(maxSnippetLength))
        }
        
        let startIndex = max(line.startIndex, line.index(range.lowerBound, offsetBy: -30))
        let endIndex = min(line.endIndex, line.index(range.upperBound, offsetBy: 30))
        
        let snippet = String(line[startIndex..<endIndex])
        return snippet.count > maxSnippetLength ? String(snippet.prefix(maxSnippetLength)) + "..." : snippet
    }
    
    private func getContextForMatch(content: String, range: Range<String.Index>) -> String {
        let lines = content.components(separatedBy: .newlines)
        let matchPosition = content.distance(from: content.startIndex, to: range.lowerBound)
        
        var currentPosition = 0
        for line in lines {
            let lineEndPosition = currentPosition + line.count
            if matchPosition >= currentPosition && matchPosition <= lineEndPosition {
                return line
            }
            currentPosition = lineEndPosition + 1 // +1 for newline
        }
        
        return ""
    }
    
    private func calculatePage(position: Int, totalLength: Int, totalPages: Int) -> Int? {
        guard totalLength > 0 && totalPages > 0 else { return nil }
        let progress = Double(position) / Double(totalLength)
        return max(1, min(totalPages, Int(ceil(progress * Double(totalPages)))))
    }
    
    private func calculateRelevance(line: String, searchText: String) -> Double {
        let lineLength = Double(line.count)
        let searchLength = Double(searchText.count)
        
        // 基础相关性：搜索词长度占比
        var relevance = searchLength / lineLength
        
        // 如果是完整词匹配，提高相关性
        let words = line.components(separatedBy: .whitespacesAndNewlines)
        if words.contains(where: { $0.caseInsensitiveCompare(searchText) == .orderedSame }) {
            relevance += 0.3
        }
        
        // 如果出现在行首，提高相关性
        if line.lowercased().hasPrefix(searchText.lowercased()) {
            relevance += 0.2
        }
        
        return min(1.0, relevance)
    }
    
    // MARK: - Search History
    func addToHistory(_ query: String, resultCount: Int) async {
        let historyItem = SearchHistoryItem(
            query: query,
            timestamp: Date(),
            resultCount: resultCount
        )
        
        await MainActor.run {
            // 移除重复项
            searchHistory.removeAll { $0.query == query }
            
            // 添加到开头
            searchHistory.insert(historyItem, at: 0)
            
            // 限制历史记录数量
            if searchHistory.count > maxHistoryItems {
                searchHistory.removeLast()
            }
        }
        
        saveSearchHistory()
    }
    
    func clearHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
    }
    
    func removeFromHistory(_ item: SearchHistoryItem) {
        searchHistory.removeAll { $0.id == item.id }
        saveSearchHistory()
    }
    
    // MARK: - Quick Search
    func quickSearch(_ text: String) async -> [SearchResult] {
        let query = SearchQuery(text: text)
        return await search(query: query)
    }
    
    func searchInCurrentBook(_ text: String, bookId: String) async -> [SearchResult] {
        let query = SearchQuery(text: text, bookIds: [bookId])
        return await search(query: query)
    }
    
    // MARK: - Advanced Search
    func advancedSearch(
        text: String,
        inBooks bookIds: [String]? = nil,
        caseSensitive: Bool = false,
        wholeWords: Bool = false,
        useRegex: Bool = false
    ) async -> [SearchResult] {
        let query = SearchQuery(
            text: text,
            useRegex: useRegex,
            caseSensitive: caseSensitive,
            wholeWords: wholeWords,
            bookIds: bookIds
        )
        return await search(query: query)
    }
    
    // MARK: - Search Suggestions
    func getSearchSuggestions(for text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        
        return searchHistory
            .filter { $0.query.lowercased().contains(text.lowercased()) }
            .prefix(5)
            .map { $0.query }
    }
    
    // MARK: - Statistics
    func getSearchStatistics() -> (totalSearches: Int, uniqueQueries: Int, averageResults: Double) {
        let totalSearches = searchHistory.count
        let uniqueQueries = Set(searchHistory.map { $0.query }).count
        let averageResults = searchHistory.isEmpty ? 0 : 
            Double(searchHistory.map { $0.resultCount }.reduce(0, +)) / Double(totalSearches)
        
        return (totalSearches: totalSearches, uniqueQueries: uniqueQueries, averageResults: averageResults)
    }
    
    // MARK: - Persistence
    private func saveSearchHistory() {
        do {
            let data = try JSONEncoder().encode(searchHistory)
            UserDefaults.standard.set(data, forKey: "search_history")
        } catch {
            print("保存搜索历史失败: \(error)")
        }
    }
    
    private func loadSearchHistory() {
        guard let data = UserDefaults.standard.data(forKey: "search_history") else { return }
        
        do {
            searchHistory = try JSONDecoder().decode([SearchHistoryItem].self, from: data)
        } catch {
            print("加载搜索历史失败: \(error)")
        }
    }
    
    // MARK: - Clear Results
    func clearResults() {
        searchResults.removeAll()
        currentQuery = ""
    }
}