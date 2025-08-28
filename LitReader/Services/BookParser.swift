import Foundation
import SwiftUI
import UniformTypeIdentifiers

// BookFormat 枚举已在 Book.swift 中定义

// MARK: - Parser Error
enum ParserError: Error, LocalizedError {
    case unsupportedFormat
    case fileNotFound
    case corruptedFile
    case encodingError
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "不支持的文件格式"
        case .fileNotFound:
            return "文件未找到"
        case .corruptedFile:
            return "文件已损坏"
        case .encodingError:
            return "文件编码错误"
        case .permissionDenied:
            return "文件访问权限不足"
        }
    }
}

// MARK: - Book Parser
@MainActor
class BookParser: ObservableObject {
    static let shared = BookParser()
    
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    
    private init() {}
    
    // MARK: - Main Parse Function
    func parseFile(at url: URL) async throws -> Book {
        isProcessing = true
        progress = 0.0
        
        defer {
            isProcessing = false
            progress = 1.0
        }
        
        do {
            // 检查文件是否存在
            guard url.startAccessingSecurityScopedResource() else {
                throw ParserError.permissionDenied
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ParserError.fileNotFound
            }
            
            progress = 0.1
            
            // 检测文件格式
            let format = detectFormat(from: url)
            progress = 0.2
            
            // 解析文件
            let book = try await parseContent(from: url, format: format)
            progress = 1.0
            
            return book
            
        } catch {
            isProcessing = false
            progress = 0.0
            throw error
        }
    }
    
    // MARK: - Format Detection
    func detectFormat(from url: URL) -> BookFormat {
        let pathExtension = url.pathExtension.lowercased()
        
        for format in BookFormat.allCases {
            if format.fileExtensions.contains(pathExtension) {
                return format
            }
        }
        
        return .txt // 默认为TXT格式
    }
    
    // MARK: - Content Parsing
    private func parseContent(from url: URL, format: BookFormat) async throws -> Book {
        switch format {
        case .txt:
            return try await parseTXT(from: url)
        case .epub:
            return try await parseEPUB(from: url)
        case .pdf:
            return try await parsePDF(from: url)
        }
    }
    
    // MARK: - TXT Parser
    private func parseTXT(from url: URL) async throws -> Book {
        progress = 0.3
        
        do {
            // 尝试多种编码
            let encodings: [String.Encoding] = [.utf8, .utf16, .ascii, .shiftJIS]
            var content: String?
            
            for encoding in encodings {
                if let text = try? String(contentsOf: url, encoding: encoding) {
                    content = text
                    break
                }
            }
            
            guard let fileContent = content else {
                throw ParserError.encodingError
            }
            
            progress = 0.6
            
            // 提取元数据
            let metadata = extractMetadata(from: fileContent)
            
            // 始终使用文件名作为标题，而不是第一行内容
            let title = url.deletingPathExtension().lastPathComponent
            // 如果元数据中有作者，就使用元数据中的作者
            let author = metadata["author"] as? String ?? ""
            
            progress = 0.8
            
            // 获取文件信息
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            let creationDate = fileAttributes[.creationDate] as? Date ?? Date()
            
            // 计算页数（粗略估算）
            let totalPages = max(1, fileContent.count / 1000)
            
            let book = Book(
                id: UUID().uuidString,
                title: title,
                author: author,
                filePath: url.path,
                format: .txt,
                fileSize: fileSize,
                addedAt: creationDate,
                lastReadAt: nil,
                progress: 0.0,
                totalPages: totalPages,
                currentPage: 0,
                readingTime: 0,
                openCount: 0,
                isFavorite: false,
                tags: [],
                notes: "",
                coverImagePath: nil,
                metadata: metadata.compactMapValues { $0 as? String },
                lastSyncAt: nil,
                updatedAt: Date()
            )
            
            progress = 1.0
            return book
            
        } catch {
            throw ParserError.corruptedFile
        }
    }
    
    // MARK: - EPUB Parser
    private func parseEPUB(from url: URL) async throws -> Book {
        progress = 0.3
        
        // EPUB解析需要解压ZIP并读取OPF文件
        // 这里简化实现，实际需要ZIP解析库
        
        let title = url.deletingPathExtension().lastPathComponent
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0
        
        let book = Book(
            id: UUID().uuidString,
            title: title,
            author: "EPUB作者",
            filePath: url.path,
            format: .epub,
            fileSize: fileSize,
            addedAt: Date(),
            lastReadAt: nil,
            progress: 0.0,
            totalPages: 100, // 默认页数
            currentPage: 0,
            readingTime: 0,
            openCount: 0,
            isFavorite: false,
            tags: ["EPUB"],
            notes: "",
            coverImagePath: nil,
            metadata: [:],
            lastSyncAt: nil,
            updatedAt: Date()
        )
        
        progress = 1.0
        return book
    }
    
    // MARK: - PDF Parser
    private func parsePDF(from url: URL) async throws -> Book {
        progress = 0.3
        
        // PDF解析需要PDFKit
        let title = url.deletingPathExtension().lastPathComponent
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0
        
        let book = Book(
            id: UUID().uuidString,
            title: title,
            author: "PDF作者",
            filePath: url.path,
            format: .pdf,
            fileSize: fileSize,
            addedAt: Date(),
            lastReadAt: nil,
            progress: 0.0,
            totalPages: 50, // 默认页数
            currentPage: 0,
            readingTime: 0,
            openCount: 0,
            isFavorite: false,
            tags: ["PDF"],
            notes: "",
            coverImagePath: nil,
            metadata: [:],
            lastSyncAt: nil,
            updatedAt: Date()
        )
        
        progress = 1.0
        return book
    }
    
    // MARK: - Metadata Extraction
    func extractMetadata(from content: String) -> [String: Any] {
        var metadata: [String: Any] = [:]
        
        let lines = content.components(separatedBy: .newlines).prefix(20)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 检查标题模式
            if trimmedLine.hasPrefix("标题：") || trimmedLine.hasPrefix("Title:") {
                let title = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty {
                    metadata["title"] = title
                }
            }
            
            // 检查作者模式
            if trimmedLine.hasPrefix("作者：") || trimmedLine.hasPrefix("Author:") {
                let author = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !author.isEmpty {
                    metadata["author"] = author
                }
            }
            
            // 检查简介模式
            if trimmedLine.hasPrefix("简介：") || trimmedLine.hasPrefix("Summary:") {
                let summary = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !summary.isEmpty {
                    metadata["summary"] = summary
                }
            }
        }
        
        return metadata
    }
    
    // MARK: - Supported Formats
    func getSupportedFormats() -> [BookFormat] {
        return BookFormat.allCases
    }
    
    func isFormatSupported(_ format: BookFormat) -> Bool {
        return getSupportedFormats().contains(format)
    }
    
    // MARK: - File Content Reading
    func getFileContent(_ filePath: String) async throws -> String {
        let url = URL(fileURLWithPath: filePath)
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw ParserError.fileNotFound
        }
        
        // 根据文件格式读取内容
        let format = detectFormat(from: url)
        
        switch format {
        case .txt:
            return try await readTXTContent(from: url)
        case .epub:
            return try await readEPUBContent(from: url)
        case .pdf:
            return try await readPDFContent(from: url)
        }
    }
    
    private func readTXTContent(from url: URL) async throws -> String {
        let encodings: [String.Encoding] = [.utf8, .utf16, .ascii]
        
        for encoding in encodings {
            if let content = try? String(contentsOf: url, encoding: encoding) {
                return content
            }
        }
        
        throw ParserError.encodingError
    }
    
    private func readEPUBContent(from url: URL) async throws -> String {
        // 简化的EPUB内容读取
        return "EPUB内容读取功能开发中..."
    }
    
    private func readPDFContent(from url: URL) async throws -> String {
        // 简化的PDF内容读取
        return "PDF内容读取功能开发中..."
    }
}