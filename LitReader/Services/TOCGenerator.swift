import Foundation
import SwiftUI
import Combine

// MARK: - Table of Contents Models
struct TableOfContents: Codable, Identifiable {
    let id: UUID
    let bookId: String
    var chapters: [Chapter]
    let generatedAt: Date
    let method: GenerationMethod
    let confidence: Double // 0.0 - 1.0
    
    init(id: UUID = UUID(), bookId: String, chapters: [Chapter], generatedAt: Date = Date(), method: GenerationMethod, confidence: Double) {
        self.id = id
        self.bookId = bookId
        self.chapters = chapters
        self.generatedAt = generatedAt
        self.method = method
        self.confidence = confidence
    }
    
    enum GenerationMethod: String, Codable {
        case automatic = "automatic"
        case manual = "manual"
        case hybrid = "hybrid"
        case imported = "imported"
        
        var displayName: String {
            switch self {
            case .automatic: return "自动生成"
            case .manual: return "手动创建"
            case .hybrid: return "混合模式"
            case .imported: return "导入目录"
            }
        }
    }
}

struct Chapter: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var level: Int // 章节层级 (1, 2, 3...)
    var startPosition: Int // 在文本中的起始位置
    var endPosition: Int? // 结束位置
    var pageNumber: Int? // 页码
    var wordCount: Int?
    var subChapters: [Chapter]
    var isExpanded: Bool = true
    var confidence: Double // 检测置信度
    
    init(id: UUID = UUID(), title: String, level: Int, startPosition: Int, endPosition: Int? = nil, pageNumber: Int? = nil, wordCount: Int? = nil, subChapters: [Chapter] = [], isExpanded: Bool = true, confidence: Double) {
        self.id = id
        self.title = title
        self.level = level
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.pageNumber = pageNumber
        self.wordCount = wordCount
        self.subChapters = subChapters
        self.isExpanded = isExpanded
        self.confidence = confidence
    }
    
    // 计算属性
    var indentLevel: Int {
        return max(0, level - 1)
    }
    
    var hasSubChapters: Bool {
        return !subChapters.isEmpty
    }
    
    var formattedTitle: String {
        let indent = String(repeating: "  ", count: indentLevel)
        return "\(indent)\(title)"
    }
    
    static func == (lhs: Chapter, rhs: Chapter) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - TOC Generation Configuration
struct TOCGenerationConfig {
    let enableSmartDetection: Bool
    let enablePatternMatching: Bool
    let enableMLDetection: Bool
    let minChapterLength: Int
    let maxChapterDepth: Int
    let confidenceThreshold: Double
    let patterns: [ChapterPattern]
    
    static let `default` = TOCGenerationConfig(
        enableSmartDetection: true,
        enablePatternMatching: true,
        enableMLDetection: false, // 需要额外的ML模型
        minChapterLength: 100,
        maxChapterDepth: 5,
        confidenceThreshold: 0.6,
        patterns: ChapterPattern.defaultPatterns
    )
}

struct ChapterPattern {
    let regex: String
    let level: Int
    let weight: Double
    let description: String
    
    static let defaultPatterns = [
        ChapterPattern(regex: "^第[一二三四五六七八九十\\d]+[章节回卷部]", level: 1, weight: 0.9, description: "中文章节"),
        ChapterPattern(regex: "^Chapter\\s+\\d+", level: 1, weight: 0.8, description: "英文章节"),
        ChapterPattern(regex: "^\\d+\\.", level: 1, weight: 0.7, description: "数字编号"),
        ChapterPattern(regex: "^[一二三四五六七八九十]、", level: 1, weight: 0.8, description: "中文编号"),
        ChapterPattern(regex: "^第[一二三四五六七八九十\\d]+节", level: 2, weight: 0.7, description: "小节"),
        ChapterPattern(regex: "^\\d+\\.\\d+", level: 2, weight: 0.6, description: "二级编号"),
        ChapterPattern(regex: "^#{1,6}\\s+", level: 0, weight: 0.9, description: "Markdown标题"), // level从#数量确定
    ]
}

// MARK: - TOC Generation Statistics
struct TOCGenerationStats {
    let totalChapters: Int
    let averageChapterLength: Int
    let deepestLevel: Int
    let generationTime: TimeInterval
    let patternsMatched: [String: Int]
    let confidenceDistribution: [Double]
}

// MARK: - TOC Generator Error
enum TOCGeneratorError: Error, LocalizedError {
    case unsupportedFormat
    case noContentFound
    case patternMatchingFailed
    case insufficientContent
    case generationTimeout
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "不支持的文档格式"
        case .noContentFound:
            return "未找到文档内容"
        case .patternMatchingFailed:
            return "模式匹配失败"
        case .insufficientContent:
            return "内容不足以生成目录"
        case .generationTimeout:
            return "目录生成超时"
        case .invalidConfiguration:
            return "无效的配置参数"
        }
    }
}

// MARK: - TOC Generator
@MainActor
class TOCGenerator: ObservableObject {
    static let shared = TOCGenerator()
    
    @Published var config = TOCGenerationConfig.default
    @Published var isGenerating = false
    @Published var progress: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    private let performanceOptimizer = PerformanceOptimizer.shared
    
    private init() {}
    
    // MARK: - Public API
    func generateTOC(for book: Book, content: String) async throws -> TableOfContents {
        guard !isGenerating else {
            throw TOCGeneratorError.generationTimeout
        }
        
        isGenerating = true
        progress = 0.0
        
        defer {
            isGenerating = false
            progress = 1.0
        }
        
        performanceOptimizer.startTiming(operation: "toc_generation")
        // defer { performanceOptimizer.endTiming(operation: "toc_generation") }
        
        do {
            // 检查内容有效性
            guard !content.isEmpty else {
                throw TOCGeneratorError.noContentFound
            }
            
            guard content.count >= config.minChapterLength else {
                throw TOCGeneratorError.insufficientContent
            }
            
            progress = 0.1
            
            // 根据文档格式选择生成策略
            let chapters = try await generateChapters(content: content, format: book.format)
            progress = 0.8
            
            // 构建目录结构
            let toc = TableOfContents(
                bookId: book.id,
                chapters: chapters,
                generatedAt: Date(),
                method: .automatic,
                confidence: calculateOverallConfidence(chapters)
            )
            
            progress = 1.0
            return toc
            
        } catch {
            isGenerating = false
            progress = 0.0
            throw error
        }
    }
    
    // MARK: - Chapter Generation
    private func generateChapters(content: String, format: BookFormat) async throws -> [Chapter] {
        switch format {
        case .txt:
            return try await generateChaptersFromText(content)
        case .epub:
            return try await generateChaptersFromEPUB(content)
        case .pdf:
            return try await generateChaptersFromPDF(content)
        }
    }
    
    private func generateChaptersFromText(_ content: String) async throws -> [Chapter] {
        var chapters: [Chapter] = []
        let lines = content.components(separatedBy: .newlines)
        
        progress = 0.2
        
        // 第一遍：使用模式匹配查找章节标题
        var potentialChapters = findChapterCandidates(in: lines)
        progress = 0.4
        
        // 第二遍：智能过滤和合并
        potentialChapters = filterAndMergeChapters(potentialChapters, content: content)
        progress = 0.6
        
        // 第三遍：构建层级结构
        chapters = buildChapterHierarchy(potentialChapters)
        progress = 0.7
        
        return chapters
    }
    
    private func generateChaptersFromEPUB(_ content: String) async throws -> [Chapter] {
        // EPUB格式通常有内置的导航文档
        var chapters: [Chapter] = []
        
        // 尝试解析EPUB的nav.xhtml或ncx文件
        if let navChapters = try? parseEPUBNavigation(content) {
            chapters = navChapters
        } else {
            // 回退到文本模式
            chapters = try await generateChaptersFromText(content)
        }
        
        return chapters
    }
    
    private func generateChaptersFromPDF(_ content: String) async throws -> [Chapter] {
        // PDF可能有书签信息，但这里我们处理提取的文本
        return try await generateChaptersFromText(content)
    }
    
    // MARK: - Pattern Matching
    private func findChapterCandidates(in lines: [String]) -> [Chapter] {
        var candidates: [Chapter] = []
        var currentPosition = 0
        
        for (_, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行和短行
            guard !trimmedLine.isEmpty && trimmedLine.count >= 2 else {
                currentPosition += line.count + 1
                continue
            }
            
            // 检查每个模式
            for pattern in config.patterns {
                if let match = matchPattern(pattern, in: trimmedLine) {
                    let chapter = Chapter(
                        title: match.title,
                        level: match.level,
                        startPosition: currentPosition,
                        endPosition: nil,
                        pageNumber: nil,
                        wordCount: nil,
                        subChapters: [],
                        confidence: match.confidence
                    )
                    
                    candidates.append(chapter)
                    break // 只匹配第一个模式
                }
            }
            
            currentPosition += line.count + 1
        }
        
        return candidates
    }
    
    private func matchPattern(_ pattern: ChapterPattern, in line: String) -> (title: String, level: Int, confidence: Double)? {
        do {
            let regex = try NSRegularExpression(pattern: pattern.regex, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: line.utf16.count)
            
            if regex.firstMatch(in: line, options: [], range: range) != nil {
                var level = pattern.level
                var title = line
                var confidence = pattern.weight
                
                // 特殊处理Markdown标题
                if pattern.description == "Markdown标题" {
                    let hashCount = line.prefix { $0 == "#" }.count
                    level = hashCount
                    title = String(line.dropFirst(hashCount).trimmingCharacters(in: .whitespaces))
                }
                
                // 根据标题特征调整置信度
                confidence = adjustConfidenceByTitleFeatures(title: title, baseConfidence: confidence)
                
                return (title: title, level: level, confidence: confidence)
            }
        } catch {
            print("正则表达式错误: \(error)")
        }
        
        return nil
    }
    
    private func adjustConfidenceByTitleFeatures(title: String, baseConfidence: Double) -> Double {
        var confidence = baseConfidence
        
        // 标题长度适中加分
        if title.count >= 3 && title.count <= 50 {
            confidence += 0.1
        }
        
        // 包含特定关键词加分
        let chapterKeywords = ["章", "节", "部", "篇", "卷", "chapter", "section", "part"]
        if chapterKeywords.contains(where: { title.lowercased().contains($0) }) {
            confidence += 0.1
        }
        
        // 全大写或全小写减分
        if title == title.uppercased() || title == title.lowercased() {
            confidence -= 0.1
        }
        
        // 包含标点符号末尾减分
        if title.hasSuffix("。") || title.hasSuffix(".") || title.hasSuffix("！") || title.hasSuffix("!") {
            confidence -= 0.1
        }
        
        return max(0.0, min(1.0, confidence))
    }
    
    // MARK: - Filtering and Merging
    private func filterAndMergeChapters(_ candidates: [Chapter], content: String) -> [Chapter] {
        var filtered: [Chapter] = []
        
        // 按置信度和位置排序
        let sorted = candidates.sorted { chapter1, chapter2 in
            if chapter1.startPosition != chapter2.startPosition {
                return chapter1.startPosition < chapter2.startPosition
            }
            return chapter1.confidence > chapter2.confidence
        }
        
        for chapter in sorted {
            // 过滤低置信度的章节
            guard chapter.confidence >= config.confidenceThreshold else {
                continue
            }
            
            // 检查是否与已有章节重复或过于接近
            let isDuplicate = filtered.contains { existingChapter in
                abs(existingChapter.startPosition - chapter.startPosition) < 50
            }
            
            if !isDuplicate {
                var mutableChapter = chapter
                
                // 设置章节结束位置
                if let nextChapter = sorted.first(where: { $0.startPosition > chapter.startPosition }) {
                    mutableChapter.endPosition = nextChapter.startPosition
                } else {
                    mutableChapter.endPosition = content.count
                }
                
                // 计算字数
                if let endPos = mutableChapter.endPosition {
                    let chapterContent = String(content[content.index(content.startIndex, offsetBy: mutableChapter.startPosition)..<content.index(content.startIndex, offsetBy: endPos)])
                    mutableChapter.wordCount = chapterContent.count
                }
                
                filtered.append(mutableChapter)
            }
        }
        
        return filtered
    }
    
    // MARK: - Hierarchy Building
    private func buildChapterHierarchy(_ chapters: [Chapter]) -> [Chapter] {
        guard !chapters.isEmpty else { return [] }
        
        var rootChapters: [Chapter] = []
        var chapterStack: [Chapter] = []
        
        for chapter in chapters {
            // 移除层级更高或相等的章节
            while let lastChapter = chapterStack.last, lastChapter.level >= chapter.level {
                chapterStack.removeLast()
            }
            
            var mutableChapter = chapter
            
            if chapterStack.last != nil {
                // 添加为子章节
                if var parent = chapterStack.last {
                    parent.subChapters.append(mutableChapter)
                    chapterStack[chapterStack.count - 1] = parent
                }
            } else {
                // 添加为根章节
                rootChapters.append(mutableChapter)
            }
            
            chapterStack.append(mutableChapter)
        }
        
        return rootChapters
    }
    
    // MARK: - EPUB Navigation Parsing
    private func parseEPUBNavigation(_ content: String) throws -> [Chapter]? {
        // 这里应该解析EPUB的navigation document
        // 简化实现，实际需要XML解析
        return nil
    }
    
    // MARK: - Manual Chapter Management
    func addChapter(_ title: String, position: Int, level: Int = 1, to toc: inout TableOfContents) {
        let chapter = Chapter(
            title: title,
            level: level,
            startPosition: position,
            endPosition: nil,
            pageNumber: nil,
            wordCount: nil,
            subChapters: [],
            confidence: 1.0 // 手动添加的章节置信度为1
        )
        
        toc.chapters.append(chapter)
        toc.chapters.sort { $0.startPosition < $1.startPosition }
    }
    
    func updateChapter(_ chapterId: UUID, title: String? = nil, level: Int? = nil, in toc: inout TableOfContents) {
        updateChapterRecursive(chapterId: chapterId, title: title, level: level, chapters: &toc.chapters)
    }
    
    private func updateChapterRecursive(chapterId: UUID, title: String?, level: Int?, chapters: inout [Chapter]) {
        for i in 0..<chapters.count {
            if chapters[i].id == chapterId {
                if let newTitle = title {
                    chapters[i].title = newTitle
                }
                if let newLevel = level {
                    chapters[i].level = newLevel
                }
                return
            }
            
            updateChapterRecursive(chapterId: chapterId, title: title, level: level, chapters: &chapters[i].subChapters)
        }
    }
    
    func removeChapter(_ chapterId: UUID, from toc: inout TableOfContents) {
        removeChapterRecursive(chapterId: chapterId, chapters: &toc.chapters)
    }
    
    private func removeChapterRecursive(chapterId: UUID, chapters: inout [Chapter]) {
        chapters.removeAll { $0.id == chapterId }
        
        for i in 0..<chapters.count {
            removeChapterRecursive(chapterId: chapterId, chapters: &chapters[i].subChapters)
        }
    }
    
    // MARK: - Utility Methods
    private func calculateOverallConfidence(_ chapters: [Chapter]) -> Double {
        guard !chapters.isEmpty else { return 0.0 }
        
        let allChapters = getAllChaptersFlat(chapters)
        let totalConfidence = allChapters.reduce(0.0) { $0 + $1.confidence }
        
        return totalConfidence / Double(allChapters.count)
    }
    
    private func getAllChaptersFlat(_ chapters: [Chapter]) -> [Chapter] {
        var result: [Chapter] = []
        
        for chapter in chapters {
            result.append(chapter)
            result.append(contentsOf: getAllChaptersFlat(chapter.subChapters))
        }
        
        return result
    }
    
    func getChapterByPosition(_ position: Int, in toc: TableOfContents) -> Chapter? {
        return findChapterByPosition(position, in: toc.chapters)
    }
    
    private func findChapterByPosition(_ position: Int, in chapters: [Chapter]) -> Chapter? {
        for chapter in chapters {
            if let endPos = chapter.endPosition {
                if position >= chapter.startPosition && position < endPos {
                    // 检查子章节
                    if let subChapter = findChapterByPosition(position, in: chapter.subChapters) {
                        return subChapter
                    }
                    return chapter
                }
            } else if position >= chapter.startPosition {
                return chapter
            }
        }
        
        return nil
    }
    
    func getNavigationInfo(currentPosition: Int, in toc: TableOfContents) -> (current: Chapter?, previous: Chapter?, next: Chapter?) {
        let allChapters = getAllChaptersFlat(toc.chapters).sorted { $0.startPosition < $1.startPosition }
        
        var current: Chapter?
        var previous: Chapter?
        var next: Chapter?
        
        for (index, chapter) in allChapters.enumerated() {
            if let endPos = chapter.endPosition {
                if currentPosition >= chapter.startPosition && currentPosition < endPos {
                    current = chapter
                    previous = index > 0 ? allChapters[index - 1] : nil
                    next = index < allChapters.count - 1 ? allChapters[index + 1] : nil
                    break
                }
            }
        }
        
        return (current: current, previous: previous, next: next)
    }
    
    // MARK: - Statistics
    func generateStatistics(for toc: TableOfContents) -> TOCGenerationStats {
        let allChapters = getAllChaptersFlat(toc.chapters)
        let totalChapters = allChapters.count
        
        let averageLength = allChapters.compactMap { $0.wordCount }.reduce(0, +) / max(1, allChapters.count)
        let deepestLevel = allChapters.map { $0.level }.max() ?? 0
        let confidences = allChapters.map { $0.confidence }
        
        return TOCGenerationStats(
            totalChapters: totalChapters,
            averageChapterLength: averageLength,
            deepestLevel: deepestLevel,
            generationTime: 0, // 实际实现中应该记录
            patternsMatched: [:], // 实际实现中应该统计
            confidenceDistribution: confidences
        )
    }
    
    // MARK: - Export/Import
    func exportTOC(_ toc: TableOfContents) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(toc)
    }
    
    func importTOC(from data: Data) throws -> TableOfContents {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TableOfContents.self, from: data)
    }
}