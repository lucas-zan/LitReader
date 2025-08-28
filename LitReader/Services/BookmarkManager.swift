import Foundation
import SwiftUI
import Combine

// MARK: - Bookmark Model
struct Bookmark: Identifiable, Codable, Hashable {
    let id: UUID
    let bookId: String
    let position: Int
    let title: String
    let note: String
    let category: String
    let createdAt: Date
    let updatedAt: Date
    let page: Int?
    let snippet: String?
    
    init(bookId: String, position: Int, title: String, note: String = "", 
         category: String = "默认", page: Int? = nil, snippet: String? = nil) {
        self.id = UUID()
        self.bookId = bookId
        self.position = position
        self.title = title
        self.note = note
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
        self.page = page
        self.snippet = snippet
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Bookmark, rhs: Bookmark) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Bookmark Category
struct BookmarkCategory: Identifiable, Codable {
    let id: UUID
    var name: String
    var color: String
    var icon: String
    let createdAt: Date
    
    init(name: String, color: String = "blue", icon: String = "bookmark") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = Date()
    }
}

// MARK: - Bookmark Statistics
struct BookmarkStatistics {
    let totalBookmarks: Int
    let bookmarksThisWeek: Int
    let bookmarksThisMonth: Int
    let categoryCounts: [String: Int]
    let mostBookmarkedBook: String?
    let averageBookmarksPerBook: Double
}

// MARK: - Bookmark Manager
@MainActor
class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()
    
    @Published var bookmarks: [Bookmark] = []
    @Published var categories: [BookmarkCategory] = []
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        setupDefaultCategories()
        loadBookmarks()
        loadCategories()
    }
    
    // MARK: - Setup
    private func setupDefaultCategories() {
        let defaultCategories = [
            BookmarkCategory(name: "默认", color: "blue", icon: "bookmark"),
            BookmarkCategory(name: "重要", color: "red", icon: "exclamationmark"),
            BookmarkCategory(name: "疑问", color: "orange", icon: "questionmark"),
            BookmarkCategory(name: "喜欢", color: "green", icon: "heart"),
            BookmarkCategory(name: "笔记", color: "purple", icon: "note.text")
        ]
        
        if categories.isEmpty {
            categories = defaultCategories
            saveCategories()
        }
    }
    
    // MARK: - Bookmark Management
    func addBookmark(_ bookmark: Bookmark) {
        // 检查是否已存在相同位置的书签
        if let existingIndex = bookmarks.firstIndex(where: { 
            $0.bookId == bookmark.bookId && $0.position == bookmark.position 
        }) {
            // 更新现有书签
            bookmarks[existingIndex] = Bookmark(
                bookId: bookmark.bookId,
                position: bookmark.position,
                title: bookmark.title,
                note: bookmark.note,
                category: bookmark.category,
                page: bookmark.page,
                snippet: bookmark.snippet
            )
        } else {
            // 添加新书签
            bookmarks.append(bookmark)
        }
        
        saveBookmarks()
    }
    
    func updateBookmark(_ bookmark: Bookmark) {
        if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            var updatedBookmark = bookmark
            // 更新时间戳
            updatedBookmark = Bookmark(
                bookId: bookmark.bookId,
                position: bookmark.position,
                title: bookmark.title,
                note: bookmark.note,
                category: bookmark.category,
                page: bookmark.page,
                snippet: bookmark.snippet
            )
            bookmarks[index] = updatedBookmark
            saveBookmarks()
        }
    }
    
    func deleteBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }
    
    func deleteBookmarks(for bookId: String) {
        bookmarks.removeAll { $0.bookId == bookId }
        saveBookmarks()
    }
    
    func deleteBookmarks(in category: String) {
        bookmarks.removeAll { $0.category == category }
        saveBookmarks()
    }
    
    // MARK: - Bookmark Queries
    func getBookmarks(for bookId: String) -> [Bookmark] {
        return bookmarks
            .filter { $0.bookId == bookId }
            .sorted { $0.position < $1.position }
    }
    
    func getBookmarks(in category: String) -> [Bookmark] {
        return bookmarks
            .filter { $0.category == category }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    func getAllBookmarks() -> [Bookmark] {
        return bookmarks.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getRecentBookmarks(limit: Int = 10) -> [Bookmark] {
        return bookmarks
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }
    
    func searchBookmarks(query: String) -> [Bookmark] {
        let lowercaseQuery = query.lowercased()
        return bookmarks.filter { bookmark in
            bookmark.title.lowercased().contains(lowercaseQuery) ||
            bookmark.note.lowercased().contains(lowercaseQuery) ||
            bookmark.snippet?.lowercased().contains(lowercaseQuery) == true
        }
    }
    
    func getBookmarkAt(bookId: String, position: Int) -> Bookmark? {
        return bookmarks.first { $0.bookId == bookId && $0.position == position }
    }
    
    func hasBookmarkAt(bookId: String, position: Int) -> Bool {
        return getBookmarkAt(bookId: bookId, position: position) != nil
    }
    
    // MARK: - Category Management
    func addCategory(_ category: BookmarkCategory) {
        categories.append(category)
        saveCategories()
    }
    
    func addCategory(name: String, color: String = "blue", icon: String = "bookmark") {
        let category = BookmarkCategory(name: name, color: color, icon: icon)
        addCategory(category)
    }
    
    func updateCategory(_ category: BookmarkCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }
    
    func deleteCategory(_ category: BookmarkCategory) {
        // 将该分类下的书签移到默认分类
        let bookmarksToUpdate = bookmarks.filter { $0.category == category.name }
        for bookmark in bookmarksToUpdate {
            let updatedBookmark = Bookmark(
                bookId: bookmark.bookId,
                position: bookmark.position,
                title: bookmark.title,
                note: bookmark.note,
                category: "默认",
                page: bookmark.page,
                snippet: bookmark.snippet
            )
            updateBookmark(updatedBookmark)
        }
        
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    func getCategories() -> [String] {
        return categories.map { $0.name }
    }
    
    func getCategoryByName(_ name: String) -> BookmarkCategory? {
        return categories.first { $0.name == name }
    }
    
    // MARK: - Bookmark Organization
    func moveBookmark(_ bookmark: Bookmark, toCategory category: String) {
        let updatedBookmark = Bookmark(
            bookId: bookmark.bookId,
            position: bookmark.position,
            title: bookmark.title,
            note: bookmark.note,
            category: category,
            page: bookmark.page,
            snippet: bookmark.snippet
        )
        updateBookmark(updatedBookmark)
    }
    
    func duplicateBookmark(_ bookmark: Bookmark, newTitle: String? = nil) {
        let newBookmark = Bookmark(
            bookId: bookmark.bookId,
            position: bookmark.position,
            title: newTitle ?? "\(bookmark.title) (副本)",
            note: bookmark.note,
            category: bookmark.category,
            page: bookmark.page,
            snippet: bookmark.snippet
        )
        addBookmark(newBookmark)
    }
    
    // MARK: - Bookmark Export/Import
    func exportBookmarks() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let exportData = BookmarkExportData(
            bookmarks: bookmarks,
            categories: categories,
            exportDate: Date(),
            version: "1.0"
        )
        
        return try encoder.encode(exportData)
    }
    
    func importBookmarks(from data: Data, mergeStrategy: ImportMergeStrategy = .skip) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importData = try decoder.decode(BookmarkExportData.self, from: data)
        
        // 导入分类
        for category in importData.categories {
            if !categories.contains(where: { $0.name == category.name }) {
                categories.append(category)
            }
        }
        
        // 导入书签
        for bookmark in importData.bookmarks {
            let existingBookmark = bookmarks.first { 
                $0.bookId == bookmark.bookId && $0.position == bookmark.position 
            }
            
            switch mergeStrategy {
            case .skip:
                if existingBookmark == nil {
                    bookmarks.append(bookmark)
                }
            case .replace:
                if let existing = existingBookmark {
                    deleteBookmark(existing)
                }
                bookmarks.append(bookmark)
            case .merge:
                if let existing = existingBookmark {
                    // 合并笔记内容
                    let mergedNote = existing.note.isEmpty ? bookmark.note : 
                                   bookmark.note.isEmpty ? existing.note :
                                   "\(existing.note)\n\n---\n\n\(bookmark.note)"
                    
                    let mergedBookmark = Bookmark(
                        bookId: bookmark.bookId,
                        position: bookmark.position,
                        title: bookmark.title,
                        note: mergedNote,
                        category: bookmark.category,
                        page: bookmark.page,
                        snippet: bookmark.snippet
                    )
                    updateBookmark(mergedBookmark)
                } else {
                    bookmarks.append(bookmark)
                }
            }
        }
        
        saveBookmarks()
        saveCategories()
    }
    
    enum ImportMergeStrategy {
        case skip      // 跳过已存在的书签
        case replace   // 替换已存在的书签
        case merge     // 合并书签内容
    }
    
    // MARK: - Statistics
    func getStatistics() -> BookmarkStatistics {
        let total = bookmarks.count
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        
        let thisWeek = bookmarks.filter { $0.createdAt >= oneWeekAgo }.count
        let thisMonth = bookmarks.filter { $0.createdAt >= oneMonthAgo }.count
        
        // 分类统计
        let categoryCounts = Dictionary(grouping: bookmarks, by: { $0.category })
            .mapValues { $0.count }
        
        // 最多书签的书籍
        let bookCounts = Dictionary(grouping: bookmarks, by: { $0.bookId })
            .mapValues { $0.count }
        let mostBookmarkedBookId = bookCounts.max { $0.value < $1.value }?.key
        
        // 平均每本书的书签数
        let uniqueBooks = Set(bookmarks.map { $0.bookId }).count
        let averagePerBook = uniqueBooks > 0 ? Double(total) / Double(uniqueBooks) : 0
        
        return BookmarkStatistics(
            totalBookmarks: total,
            bookmarksThisWeek: thisWeek,
            bookmarksThisMonth: thisMonth,
            categoryCounts: categoryCounts,
            mostBookmarkedBook: mostBookmarkedBookId,
            averageBookmarksPerBook: averagePerBook
        )
    }
    
    // MARK: - Cleanup
    func cleanupOrphanedBookmarks() {
        let dataManager = DataManager.shared
        let validBookIds = Set(dataManager.library.books.map { $0.id })
        
        let initialCount = bookmarks.count
        bookmarks.removeAll { !validBookIds.contains($0.bookId) }
        
        if bookmarks.count < initialCount {
            saveBookmarks()
        }
    }
    
    func clearAllBookmarks() {
        bookmarks.removeAll()
        saveBookmarks()
    }
    
    // MARK: - Persistence
    private func saveBookmarks() {
        do {
            let data = try JSONEncoder().encode(bookmarks)
            userDefaults.set(data, forKey: "bookmarks")
        } catch {
            print("保存书签失败: \(error)")
        }
    }
    
    private func loadBookmarks() {
        guard let data = userDefaults.data(forKey: "bookmarks") else { return }
        
        do {
            bookmarks = try JSONDecoder().decode([Bookmark].self, from: data)
        } catch {
            print("加载书签失败: \(error)")
        }
    }
    
    private func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            userDefaults.set(data, forKey: "bookmark_categories")
        } catch {
            print("保存书签分类失败: \(error)")
        }
    }
    
    private func loadCategories() {
        guard let data = userDefaults.data(forKey: "bookmark_categories") else { return }
        
        do {
            let loadedCategories = try JSONDecoder().decode([BookmarkCategory].self, from: data)
            if !loadedCategories.isEmpty {
                categories = loadedCategories
            }
        } catch {
            print("加载书签分类失败: \(error)")
        }
    }
}

// MARK: - Export Data Structure
private struct BookmarkExportData: Codable {
    let bookmarks: [Bookmark]
    let categories: [BookmarkCategory]
    let exportDate: Date
    let version: String
}