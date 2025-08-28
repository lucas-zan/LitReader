// LitReaderSwift/Services/DataManager.swift
// 数据管理服务

import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var library = Library()
    @Published var isLoading = false
    @Published var error: Error?
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let documentsURL: URL
    private let booksDirectory: URL
    
    private init() {
        self.documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.booksDirectory = documentsURL.appendingPathComponent("LitReader/Books")
        
        createDirectoriesIfNeeded()
        loadLibrary()
    }
    
    // MARK: - 公共访问方法
    func getDocumentsURL() -> URL {
        return documentsURL
    }
    
    func getBooksDirectoryURL() -> URL {
        return booksDirectory
    }
    
    // MARK: - 初始化方法
    private func createDirectoriesIfNeeded() {
        do {
            try fileManager.createDirectory(at: booksDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create directories: \(error)")
        }
    }
    
    // MARK: - 库管理
    func loadLibrary() {
        isLoading = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                if let data = self?.userDefaults.data(forKey: "litreader_library") {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let library = try decoder.decode(Library.self, from: data)
                    
                    DispatchQueue.main.async {
                        self?.library = library
                        self?.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.library = Library()
                        self?.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.error = error
                    self?.isLoading = false
                }
            }
        }
    }
    
    private func saveLibrary() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(library)
            userDefaults.set(data, forKey: "litreader_library")
        } catch {
            self.error = error
        }
    }
    
    // MARK: - 书籍管理
    func addBook(_ book: Book) {
        library.books.append(book)
        saveLibrary()
    }
    
    func removeBook(withId id: String) {
        // 删除文件
        if let book = library.books.first(where: { $0.id == id }) {
            let fileURL = URL(fileURLWithPath: book.filePath)
            try? fileManager.removeItem(at: fileURL)
        }
        
        // 从库中移除
        library.books.removeAll { $0.id == id }
        saveLibrary()
    }
    
    func updateBook(_ book: Book) {
        if let index = library.books.firstIndex(where: { $0.id == book.id }) {
            library.books[index] = book
            saveLibrary()
        }
    }
    
    func getBook(withId id: String) -> Book? {
        return library.books.first { $0.id == id }
    }
    
    // MARK: - 阅读进度管理
    func saveProgress(_ session: ReadingSession) {
        let key = "litreader_progress_\(session.bookId)"
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(session)
            userDefaults.set(data, forKey: key)
            
            // 同时更新书籍进度
            if let index = library.books.firstIndex(where: { $0.id == session.bookId }) {
                library.books[index].progress = Double(session.endPosition) / 100.0 // 简单转换
                library.books[index].lastReadAt = session.endTime
                saveLibrary()
            }
        } catch {
            self.error = error
        }
    }
    
    func getProgress(for bookId: String) -> ReadingSession? {
        let key = "litreader_progress_\(bookId)"
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ReadingSession.self, from: data)
        } catch {
            return nil
        }
    }
    
    // MARK: - 阅读进度管理 (新方法)
    func saveReadingProgress(_ progress: ReadingProgress) {
        let key = "litreader_reading_progress_\(progress.bookId)"
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(progress)
            userDefaults.set(data, forKey: key)
            
            // 同时更新书籍进度
            if let index = library.books.firstIndex(where: { $0.id == progress.bookId }) {
                library.books[index].progress = progress.progressPercentage
                library.books[index].lastReadAt = progress.lastReadAt
                saveLibrary()
            }
        } catch {
            self.error = error
        }
    }
    
    func getReadingProgress(for bookId: String) -> ReadingProgress? {
        let key = "litreader_reading_progress_\(bookId)"
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ReadingProgress.self, from: data)
        } catch {
            return nil
        }
    }
    
    // MARK: - 书签管理
    func addBookmark(_ bookmark: Bookmark) {
        let key = "litreader_bookmarks_\(bookmark.bookId)"
        var bookmarks = getBookmarks(for: bookmark.bookId)
        bookmarks.append(bookmark)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(bookmarks)
            userDefaults.set(data, forKey: key)
        } catch {
            self.error = error
        }
    }
    
    func getBookmarks(for bookId: String) -> [Bookmark] {
        let key = "litreader_bookmarks_\(bookId)"
        guard let data = userDefaults.data(forKey: key) else { return [] }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Bookmark].self, from: data)
        } catch {
            return []
        }
    }
    
    func removeBookmark(withId id: UUID) {
        // 遍历所有书籍的书签来找到并删除
        for book in library.books {
            let key = "litreader_bookmarks_\(book.id)"
            var bookmarks = getBookmarks(for: book.id)
            
            if let index = bookmarks.firstIndex(where: { $0.id == id }) {
                bookmarks.remove(at: index)
                
                do {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    let data = try encoder.encode(bookmarks)
                    userDefaults.set(data, forKey: key)
                    return
                } catch {
                    self.error = error
                }
            }
        }
    }
    
    // MARK: - 文件内容管理
    func getBookContent(for book: Book) throws -> String {
        let fileURL = URL(fileURLWithPath: book.filePath)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw LitReaderError.fileNotFound
        }
        
        switch book.format {
        case .txt:
            return try String(contentsOf: fileURL, encoding: .utf8)
        case .epub:
            // TODO: 实现EPUB解析
            throw LitReaderError.unsupportedFormat
        case .pdf:
            // TODO: 实现PDF解析
            throw LitReaderError.unsupportedFormat
        }
    }
    
    // MARK: - 设置管理
    func saveSettings(_ settings: AppSettings) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: "litreader_settings")
        } catch {
            self.error = error
        }
    }
    
    func loadSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: "litreader_settings") else {
            return .default
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            return .default
        }
    }
    
    // MARK: - 搜索功能
    func searchBooks(query: String) -> [Book] {
        guard !query.isEmpty else { return library.books }
        
        return library.books.filter { book in
            book.title.localizedCaseInsensitiveContains(query) ||
            book.author?.localizedCaseInsensitiveContains(query) == true ||
            book.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    // MARK: - 数据清理
    func clearAllData() {
        // 删除所有文件
        try? fileManager.removeItem(at: booksDirectory.deletingLastPathComponent())
        
        // 清理UserDefaults
        let keys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("litreader_") }
        keys.forEach { userDefaults.removeObject(forKey: $0) }
        
        // 重置状态
        library = Library()
        error = nil
        
        // 重新创建目录
        createDirectoriesIfNeeded()
    }
    
    // MARK: - 扫描Books目录
    /// 扫描Books目录中的文件并自动添加到库中
    func scanBooksDirectory() {
        do {
            // 检查Books目录是否存在
            guard fileManager.fileExists(atPath: booksDirectory.path) else {
                print("Books directory does not exist")
                return
            }
            
            // 获取目录中的所有文件
            let fileURLs = try fileManager.contentsOfDirectory(at: booksDirectory, includingPropertiesForKeys: [.isRegularFileKey])
            
            // 过滤出支持的文件格式
            let supportedFiles = fileURLs.filter { url in
                let pathExtension = url.pathExtension.lowercased()
                return ["txt", "epub", "pdf"].contains(pathExtension)
            }
            
            // 检查哪些文件尚未在库中
            let existingFilePaths = Set(library.books.map { $0.filePath })
            
            for fileURL in supportedFiles {
                // 如果文件不在库中，则添加到库中
                if !existingFilePaths.contains(fileURL.path) {
                    // 创建Book对象
                    let format: BookFormat
                    switch fileURL.pathExtension.lowercased() {
                    case "txt":
                        format = .txt
                    case "epub":
                        format = .epub
                    case "pdf":
                        format = .pdf
                    default:
                        format = .txt // 默认为txt
                    }
                    
                    // 获取文件信息
                    let fileAttributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    let fileSize = fileAttributes[.size] as? Int64 ?? 0
                    let creationDate = fileAttributes[.creationDate] as? Date ?? Date()
                    
                    // 提取标题（从文件名）
                    let title = fileURL.deletingPathExtension().lastPathComponent
                    
                    // 创建Book对象
                    let book = Book(
                        title: title,
                        author: nil,
                        filePath: fileURL.path,
                        format: format,
                        fileSize: fileSize,
                        addedAt: creationDate
                    )
                    
                    // 添加到库中
                    library.books.append(book)
                }
            }
            
            // 保存更新后的库
            saveLibrary()
            
        } catch {
            print("Error scanning books directory: \(error)")
            self.error = error
        }
    }
}