// LitReaderSwift/Models/Book.swift
// 书籍数据模型

import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum BookFormat: String, CaseIterable, Codable {
    case txt = "txt"
    case epub = "epub"
    case pdf = "pdf"
    
    var displayName: String {
        switch self {
        case .txt: return "TXT文本"
        case .epub: return "EPUB电子书"
        case .pdf: return "PDF文档"
        }
    }
    
    var fileExtensions: [String] {
        switch self {
        case .txt: return ["txt", "text"]
        case .epub: return ["epub"]
        case .pdf: return ["pdf"]
        }
    }
    
    var utType: UTType {
        switch self {
        case .txt: return .plainText
        case .epub: return UTType("org.idpf.epub-container") ?? .data
        case .pdf: return .pdf
        }
    }
}

struct Book: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var author: String?
    var filePath: String
    let format: BookFormat
    let addedAt: Date
    var lastReadAt: Date?
    var progress: Double // 0.0-1.0 阅读进度百分比
    var currentChapter: Int?
    var totalChapters: Int?
    var isFavorite: Bool
    var tags: [String]
    let fileSize: Int64
    var coverPath: String?
    var openCount: Int
    let readingTime: TimeInterval // 阅读时长（秒）
    let totalPages: Int // 总页数
    let currentPage: Int // 当前页数
    var notes: String // 笔记
    let metadata: [String: String] // 元数据
    let lastSyncAt: Date? // 最后同步时间
    let updatedAt: Date // 更新时间
    let coverImagePath: String? // 封面图片路径
    
    // 计算属性
    var progressPercentage: Int {
        return Int(progress * 100)
    }
    
    var isCompleted: Bool {
        return progress >= 1.0
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         author: String? = nil,
         filePath: String,
         format: BookFormat,
         fileSize: Int64 = 0,
         addedAt: Date = Date(),
         lastReadAt: Date? = nil,
         progress: Double = 0.0,
         totalPages: Int = 1,
         currentPage: Int = 0,
         readingTime: TimeInterval = 0,
         openCount: Int = 0,
         isFavorite: Bool = false,
         tags: [String] = [],
         notes: String = "",
         coverImagePath: String? = nil,
         metadata: [String: String] = [:],
         lastSyncAt: Date? = nil,
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.author = author
        self.filePath = filePath
        self.format = format
        self.addedAt = addedAt
        self.lastReadAt = lastReadAt
        self.progress = progress
        self.currentChapter = 0
        self.totalChapters = 1
        self.isFavorite = isFavorite
        self.tags = tags
        self.fileSize = fileSize
        self.coverPath = nil
        self.openCount = openCount
        self.readingTime = readingTime
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.notes = notes
        self.metadata = metadata
        self.lastSyncAt = lastSyncAt
        self.updatedAt = updatedAt
        self.coverImagePath = coverImagePath
    }
}

// MARK: - Book 示例数据
extension Book {
    static let example = Book(
        title: "示例书籍",
        author: "示例作者",
        filePath: "/example/path/book.txt",
        format: .txt,
        fileSize: 1024000
    )
}

// MARK: - 书架相关模型
struct Library: Codable {
    var books: [Book]
    var categories: [Category]
    let version: String
    
    init() {
        self.books = []
        self.categories = []
        self.version = "1.0.0"
    }
}

struct Category: Identifiable, Codable {
    let id: String
    var name: String
    var bookIds: [String]
    var color: String?
    
    init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        self.bookIds = []
        self.color = nil
    }
}

// MARK: - 阅读相关模型
// ReadingSession 已移动到 ReadingEngine.swift

// Bookmark 已移动到 BookmarkManager.swift

// MARK: - 主题相关模型（已移动到 ThemeManager.swift）

// MARK: - 应用设置模型
struct AppSettings: Codable, Equatable {
    var theme: AppTheme
    var defaultReadingSettings: ReadingTheme
    var autoSave: Bool
    var cloudSync: Bool
    var aiEnabled: Bool
    var language: String
    
    enum AppTheme: String, CaseIterable, Codable, Equatable {
        case auto = "auto"
        case light = "light"
        case dark = "dark"
    }
    
    static let `default` = AppSettings(
        theme: .auto,
        defaultReadingSettings: ReadingTheme(
            name: "light",
            backgroundColor: .white,
            textColor: .black,
            accentColor: .blue,
            fontSize: 16,
            fontFamily: "System",
            lineHeight: 1.5,
            pageMargin: 20,
            isDark: false
        ),
        autoSave: true,
        cloudSync: false,
        aiEnabled: false,
        language: "zh"
    )
}

// MARK: - 章节模型（已移动到 TOCGenerator.swift）

// TableOfContents 已移动到 TOCGenerator.swift

// MARK: - 错误类型
enum LitReaderError: LocalizedError {
    case fileNotFound
    case unsupportedFormat
    case parseError(String)
    case storageError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "文件未找到"
        case .unsupportedFormat:
            return "不支持的文件格式"
        case .parseError(let message):
            return "解析错误: \(message)"
        case .storageError(let message):
            return "存储错误: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        }
    }
}