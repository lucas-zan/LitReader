// LitReaderSwift/Services/FileImporter.swift
// 文件导入服务

import Foundation
import UniformTypeIdentifiers
import UIKit

class FileImporter: ObservableObject {
    static let shared = FileImporter()
    
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var error: Error?
    
    private let fileManager = FileManager.default
    private let dataManager = DataManager.shared
    
    private init() {}
    
    // MARK: - 文件导入
    func importFiles(from urls: [URL]) async {
        await MainActor.run {
            isImporting = true
            importProgress = 0.0
            error = nil
        }
        
        let totalFiles = Double(urls.count)
        
        for (index, url) in urls.enumerated() {
            do {
                let book = try await processFile(url: url)
                
                await MainActor.run {
                    dataManager.addBook(book)
                    importProgress = Double(index + 1) / totalFiles
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
        
        await MainActor.run {
            isImporting = false
            importProgress = 1.0
        }
    }
    
    private func processFile(url: URL) async throws -> Book {
        // 获取文件访问权限
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        
        // 验证文件格式
        guard let format = getBookFormat(from: url) else {
            throw LitReaderError.unsupportedFormat
        }
        
        // 获取文件信息
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // 验证文件大小 (限制100MB)
        let maxSize: Int64 = 100 * 1024 * 1024
        guard fileSize <= maxSize else {
            throw LitReaderError.parseError("文件过大，请选择小于100MB的文件")
        }
        
        // 复制文件到应用目录
        let fileName = "\(UUID().uuidString)_\(url.lastPathComponent)"
        let destinationURL = dataManager.getDocumentsURL()
            .appendingPathComponent("LitReader/Books")
            .appendingPathComponent(fileName)
        
        try fileManager.copyItem(at: url, to: destinationURL)
        
        // 解析文件内容
        let (title, author, _) = try parseFileMetadata(url: destinationURL, format: format)
        
        // 创建书籍对象
        let book = Book(
            title: title,
            author: author,
            filePath: destinationURL.path,
            format: format,
            fileSize: fileSize
        )
        
        return book
    }
    
    private func getBookFormat(from url: URL) -> BookFormat? {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "txt":
            return .txt
        case "epub":
            return .epub
        case "pdf":
            return .pdf
        default:
            return nil
        }
    }
    
    private func parseFileMetadata(url: URL, format: BookFormat) throws -> (title: String, author: String?, chapterCount: Int) {
        switch format {
        case .txt:
            return try parseTxtMetadata(url: url)
        case .epub:
            return try parseEpubMetadata(url: url)
        case .pdf:
            return try parsePdfMetadata(url: url)
        }
    }
    
    // MARK: - TXT文件解析
    private func parseTxtMetadata(url: URL) throws -> (title: String, author: String?, chapterCount: Int) {
        let content = try String(contentsOf: url, encoding: .utf8)
        
        // 提取标题（始终使用文件名，去掉后缀和前缀）
        var title = url.deletingPathExtension().lastPathComponent
        
        // 如果文件名包含UUID前缀（格式为：XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX_），则去除
        if let underscoreIndex = title.firstIndex(of: "_"), 
           title.distance(from: title.startIndex, to: underscoreIndex) >= 36,
           title.prefix(8).allSatisfy({ $0.isHexDigit }) {
            title = String(title[title.index(after: underscoreIndex)...])
        }
        
        // 提取作者信息
        var author: String?
        let authorPattern = #"作者[：:]\s*(.+)"#
        if let regex = try? NSRegularExpression(pattern: authorPattern, options: []),
           let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) {
            if let authorRange = Range(match.range(at: 1), in: content) {
                author = String(content[authorRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // 估算章节数量
        let chapterCount = estimateChapterCount(in: content)
        
        return (title: title, author: author, chapterCount: chapterCount)
    }
    
    private func estimateChapterCount(in content: String) -> Int {
        let patterns = [
            #"第[一二三四五六七八九十百千万\d]+章"#,
            #"第[一二三四五六七八九十百千万\d]+节"#,
            #"Chapter\s+\d+"#,
            #"^\s*\d+[\.\s]"#
        ]
        
        var maxCount = 1
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
                let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
                maxCount = max(maxCount, matches.count)
            }
        }
        
        return maxCount
    }
    
    // MARK: - EPUB文件解析 (基础实现)
    private func parseEpubMetadata(url: URL) throws -> (title: String, author: String?, chapterCount: Int) {
        // 基础实现，返回文件名作为标题
        var title = url.deletingPathExtension().lastPathComponent
        
        // 如果文件名包含UUID前缀（格式为：XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX_），则去除
        if let underscoreIndex = title.firstIndex(of: "_"), 
           title.distance(from: title.startIndex, to: underscoreIndex) >= 36,
           title.prefix(8).allSatisfy({ $0.isHexDigit }) {
            title = String(title[title.index(after: underscoreIndex)...])
        }
        
        // TODO: 实现完整的EPUB解析
        // 这里可以使用第三方库如ZIPFoundation来解析EPUB文件
        
        return (title: title, author: nil, chapterCount: 1)
    }
    
    // MARK: - PDF文件解析 (基础实现)
    private func parsePdfMetadata(url: URL) throws -> (title: String, author: String?, chapterCount: Int) {
        // 基础实现，返回文件名作为标题
        var title = url.deletingPathExtension().lastPathComponent
        
        // 如果文件名包含UUID前缀（格式为：XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX_），则去除
        if let underscoreIndex = title.firstIndex(of: "_"), 
           title.distance(from: title.startIndex, to: underscoreIndex) >= 36,
           title.prefix(8).allSatisfy({ $0.isHexDigit }) {
            title = String(title[title.index(after: underscoreIndex)...])
        }
        
        // TODO: 实现完整的PDF解析
        // 这里可以使用PDFKit来解析PDF文件信息
        
        return (title: title, author: nil, chapterCount: 1)
    }
    
    // MARK: - 辅助方法
    func getSupportedFileTypes() -> [UTType] {
        return [
            .plainText,     // TXT
            UTType(filenameExtension: "epub") ?? .data,  // EPUB
            .pdf            // PDF
        ]
    }
    
    func validateFileSize(_ url: URL, maxSizeMB: Int = 100) -> Bool {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            let maxSize: Int64 = Int64(maxSizeMB) * 1024 * 1024
            return fileSize <= maxSize
        } catch {
            return false
        }
    }
    
    func getFileSize(_ url: URL) -> Int64 {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}