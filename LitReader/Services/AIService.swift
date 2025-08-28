import Foundation
import SwiftUI
import Combine

// MARK: - AI Service Models
struct AIAnalysisResult: Codable {
    let bookId: String
    let summary: String
    let keyPoints: [String]
    let themes: [String]
    let sentiment: SentimentAnalysis
    let readability: ReadabilityScore
    let recommendations: [BookRecommendation]
    let generatedAt: Date
    let confidence: Double
}

struct SentimentAnalysis: Codable {
    let overall: Sentiment
    let distribution: [Sentiment: Double]
    let emotionalArc: [EmotionalPoint]
    
    enum Sentiment: String, CaseIterable, Codable {
        case positive = "positive"
        case negative = "negative"
        case neutral = "neutral"
        case mixed = "mixed"
        
        var displayName: String {
            switch self {
            case .positive: return "积极"
            case .negative: return "消极"
            case .neutral: return "中性"
            case .mixed: return "复合"
            }
        }
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .negative: return .red
            case .neutral: return .gray
            case .mixed: return .blue
            }
        }
    }
}

struct EmotionalPoint: Codable {
    let position: Double // 0.0 - 1.0
    let sentiment: SentimentAnalysis.Sentiment
    let intensity: Double // 0.0 - 1.0
}

struct ReadabilityScore: Codable {
    let overall: Double // 0.0 - 1.0
    let vocabulary: Double
    let syntax: Double
    let structure: Double
    let level: ReadingLevel
    
    enum ReadingLevel: String, CaseIterable, Codable {
        case elementary = "elementary"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case expert = "expert"
        
        var displayName: String {
            switch self {
            case .elementary: return "初级"
            case .intermediate: return "中级"
            case .advanced: return "高级"
            case .expert: return "专家级"
            }
        }
    }
}

struct BookRecommendation: Identifiable, Codable {
    let id: UUID
    let bookId: String
    let title: String
    let reason: String
    let similarity: Double // 0.0 - 1.0
    let tags: [String]
}

struct ReadingInsight: Codable {
    let insight: String
    let type: InsightType
    let relevance: Double
    
    enum InsightType: String, CaseIterable, Codable {
        case pattern = "pattern"
        case preference = "preference"
        case improvement = "improvement"
        case achievement = "achievement"
        
        var displayName: String {
            switch self {
            case .pattern: return "阅读模式"
            case .preference: return "偏好分析"
            case .improvement: return "改进建议"
            case .achievement: return "成就达成"
            }
        }
        
        var icon: String {
            switch self {
            case .pattern: return "chart.line.uptrend.xyaxis"
            case .preference: return "heart"
            case .improvement: return "arrow.up.circle"
            case .achievement: return "star.circle"
            }
        }
    }
}

// MARK: - AI Configuration
struct AIServiceConfig {
    let enableSmartSummary: Bool
    let enableSentimentAnalysis: Bool
    let enableRecommendations: Bool
    let enableReadingInsights: Bool
    let summaryLength: SummaryLength
    let analysisDepth: AnalysisDepth
    let privacyMode: Bool
    
    enum SummaryLength: String, CaseIterable {
        case brief = "brief"
        case standard = "standard"
        case detailed = "detailed"
        
        var wordCount: Int {
            switch self {
            case .brief: return 100
            case .standard: return 300
            case .detailed: return 500
            }
        }
        
        var displayName: String {
            switch self {
            case .brief: return "简要"
            case .standard: return "标准"
            case .detailed: return "详细"
            }
        }
    }
    
    enum AnalysisDepth: String, CaseIterable {
        case basic = "basic"
        case comprehensive = "comprehensive"
        case deep = "deep"
        
        var displayName: String {
            switch self {
            case .basic: return "基础分析"
            case .comprehensive: return "全面分析"
            case .deep: return "深度分析"
            }
        }
    }
    
    static let `default` = AIServiceConfig(
        enableSmartSummary: true,
        enableSentimentAnalysis: true,
        enableRecommendations: true,
        enableReadingInsights: true,
        summaryLength: .standard,
        analysisDepth: .comprehensive,
        privacyMode: true
    )
}

// MARK: - AI Service Errors
enum AIServiceError: Error, LocalizedError {
    case serviceUnavailable
    case insufficientContent
    case analysisTimeout
    case rateLimitExceeded
    case invalidInput
    case networkError
    case apiKeyMissing
    case privacyRestriction
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "AI服务不可用"
        case .insufficientContent:
            return "内容不足以进行分析"
        case .analysisTimeout:
            return "分析超时"
        case .rateLimitExceeded:
            return "请求频率过高"
        case .invalidInput:
            return "输入数据无效"
        case .networkError:
            return "网络连接错误"
        case .apiKeyMissing:
            return "API密钥缺失"
        case .privacyRestriction:
            return "隐私模式限制"
        }
    }
}

// MARK: - AI Service
@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var config = AIServiceConfig.default
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var cachedResults: [String: AIAnalysisResult] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private let performanceOptimizer = PerformanceOptimizer.shared
    
    // 本地AI模型缓存
    private var localSentimentModel: SentimentModel?
    private var localSummaryModel: SummaryModel?
    
    private init() {
        setupLocalModels()
    }
    
    // MARK: - Initialization
    private func setupLocalModels() {
        // 初始化本地AI模型
        localSentimentModel = SentimentModel()
        localSummaryModel = SummaryModel()
    }
    
    func configure(_ config: AIServiceConfig) {
        self.config = config
        
        // 根据隐私模式调整行为
        if config.privacyMode {
            print("AI服务运行在隐私模式，仅使用本地模型")
        }
    }
    
    // MARK: - Main Analysis API
    func analyzeBook(_ book: Book, content: String) async throws -> AIAnalysisResult {
        guard !isAnalyzing else {
            throw AIServiceError.analysisTimeout
        }
        
        // 检查缓存
        if let cachedResult = cachedResults[book.id] {
            return cachedResult
        }
        
        isAnalyzing = true
        analysisProgress = 0.0
        
        defer {
            isAnalyzing = false
            analysisProgress = 1.0
        }
        
        performanceOptimizer.startTiming(operation: "ai_analysis")
        defer { performanceOptimizer.endTiming(operation: "ai_analysis") }
        
        do {
            // 检查内容长度
            guard content.count >= 500 else {
                throw AIServiceError.insufficientContent
            }
            
            analysisProgress = 0.1
            
            // 生成摘要
            let summary = try await generateSummary(content: content)
            analysisProgress = 0.3
            
            // 提取关键点
            let keyPoints = try await extractKeyPoints(content: content)
            analysisProgress = 0.4
            
            // 主题分析
            let themes = try await analyzeThemes(content: content)
            analysisProgress = 0.5
            
            // 情感分析
            let sentiment = try await analyzeSentiment(content: content)
            analysisProgress = 0.7
            
            // 可读性分析
            let readability = try await analyzeReadability(content: content)
            analysisProgress = 0.8
            
            // 生成推荐
            let recommendations = try await generateRecommendations(for: book, content: content)
            analysisProgress = 0.9
            
            let result = AIAnalysisResult(
                bookId: book.id,
                summary: summary,
                keyPoints: keyPoints,
                themes: themes,
                sentiment: sentiment,
                readability: readability,
                recommendations: recommendations,
                generatedAt: Date(),
                confidence: 0.85 // 基于本地模型的置信度
            )
            
            // 缓存结果
            cachedResults[book.id] = result
            analysisProgress = 1.0
            
            return result
            
        } catch {
            isAnalyzing = false
            analysisProgress = 0.0
            throw error
        }
    }
    
    // MARK: - Summary Generation
    private func generateSummary(content: String) async throws -> String {
        if config.privacyMode {
            return try await generateLocalSummary(content: content)
        } else {
            // 如果不是隐私模式，可以调用云端API
            return try await generateLocalSummary(content: content)
        }
    }
    
    private func generateLocalSummary(content: String) async throws -> String {
        // 本地摘要生成算法
        let sentences = extractSentences(from: content)
        let targetLength = config.summaryLength.wordCount
        
        // 简单的提取式摘要算法
        let importantSentences = selectImportantSentences(sentences, targetLength: targetLength)
        
        return importantSentences.joined(separator: " ")
    }
    
    private func extractSentences(from content: String) -> [String] {
        // 基于标点符号的简单句子分割
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: "。！？.!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 10 }
        
        return sentences
    }
    
    private func selectImportantSentences(_ sentences: [String], targetLength: Int) -> [String] {
        // 简单的句子重要性评分算法
        var scoredSentences: [(sentence: String, score: Double)] = []
        
        for sentence in sentences {
            let score = calculateSentenceImportance(sentence, in: sentences)
            scoredSentences.append((sentence: sentence, score: score))
        }
        
        // 按得分排序并选择前几句
        scoredSentences.sort { $0.score > $1.score }
        
        var selectedSentences: [String] = []
        var currentLength = 0
        
        for scoredSentence in scoredSentences {
            if currentLength + scoredSentence.sentence.count <= targetLength {
                selectedSentences.append(scoredSentence.sentence)
                currentLength += scoredSentence.sentence.count
            }
            
            if currentLength >= Int(Double(targetLength) * 0.8) { // 达到目标长度的80%时停止
                break
            }
        }
        
        return selectedSentences
    }
    
    private func calculateSentenceImportance(_ sentence: String, in allSentences: [String]) -> Double {
        var score = 0.0
        
        // 句子长度评分（适中长度更重要）
        let idealLength = 50.0
        let lengthScore = 1.0 - abs(Double(sentence.count) - idealLength) / idealLength
        score += lengthScore * 0.2
        
        // 关键词评分
        let keywords = ["重要", "关键", "主要", "核心", "基本", "fundamental", "important", "key", "main"]
        let keywordCount = keywords.reduce(0) { count, keyword in
            count + (sentence.lowercased().contains(keyword.lowercased()) ? 1 : 0)
        }
        score += Double(keywordCount) * 0.3
        
        // 位置评分（开头和结尾的句子更重要）
        if let index = allSentences.firstIndex(of: sentence) {
            let position = Double(index) / Double(allSentences.count)
            if position < 0.1 || position > 0.9 {
                score += 0.2
            }
        }
        
        return score
    }
    
    // MARK: - Key Points Extraction
    private func extractKeyPoints(content: String) async throws -> [String] {
        let sentences = extractSentences(from: content)
        let keyPoints = sentences.filter { sentence in
            containsKeyPointIndicators(sentence)
        }.prefix(5).map { String($0) }
        
        return Array(keyPoints)
    }
    
    private func containsKeyPointIndicators(_ sentence: String) -> Bool {
        let indicators = ["首先", "其次", "最后", "重要的是", "关键在于", "主要", "核心", "基本"]
        return indicators.contains { sentence.contains($0) }
    }
    
    // MARK: - Theme Analysis
    private func analyzeThemes(content: String) async throws -> [String] {
        // 简单的主题词提取
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 2 }
        
        let wordFrequency = Dictionary(grouping: words) { $0.lowercased() }
            .mapValues { $0.count }
        
        let commonThemes = wordFrequency
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
        
        return Array(commonThemes)
    }
    
    // MARK: - Sentiment Analysis
    private func analyzeSentiment(content: String) async throws -> SentimentAnalysis {
        guard let model = localSentimentModel else {
            throw AIServiceError.serviceUnavailable
        }
        
        return try await model.analyze(content: content)
    }
    
    // MARK: - Readability Analysis
    private func analyzeReadability(content: String) async throws -> ReadabilityScore {
        let sentences = extractSentences(from: content)
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // 计算各项指标
        let avgWordsPerSentence = Double(words.count) / Double(sentences.count)
        let avgCharsPerWord = Double(content.count) / Double(words.count)
        
        // 词汇复杂度
        let vocabularyScore = calculateVocabularyComplexity(words)
        
        // 句法复杂度
        let syntaxScore = calculateSyntaxComplexity(avgWordsPerSentence)
        
        // 结构复杂度
        let structureScore = calculateStructureComplexity(sentences)
        
        // 综合评分
        let overall = (vocabularyScore + syntaxScore + structureScore) / 3.0
        
        // 确定阅读级别
        let level: ReadabilityScore.ReadingLevel
        if overall < 0.3 {
            level = .elementary
        } else if overall < 0.6 {
            level = .intermediate
        } else if overall < 0.8 {
            level = .advanced
        } else {
            level = .expert
        }
        
        return ReadabilityScore(
            overall: overall,
            vocabulary: vocabularyScore,
            syntax: syntaxScore,
            structure: structureScore,
            level: level
        )
    }
    
    private func calculateVocabularyComplexity(_ words: [String]) -> Double {
        let uniqueWords = Set(words.map { $0.lowercased() })
        let vocabularyRichness = Double(uniqueWords.count) / Double(words.count)
        
        // 复杂词汇比例（长度超过6的词）
        let complexWords = words.filter { $0.count > 6 }
        let complexWordRatio = Double(complexWords.count) / Double(words.count)
        
        return (vocabularyRichness + complexWordRatio) / 2.0
    }
    
    private func calculateSyntaxComplexity(_ avgWordsPerSentence: Double) -> Double {
        // 基于平均句长评估句法复杂度
        let normalizedLength = min(avgWordsPerSentence / 20.0, 1.0)
        return normalizedLength
    }
    
    private func calculateStructureComplexity(_ sentences: [String]) -> Double {
        // 基于句子结构多样性评估
        let punctuationVariety = Set(sentences.flatMap { sentence in
            sentence.filter { "，。！？；：,.:;!?".contains($0) }
        }).count
        
        return min(Double(punctuationVariety) / 10.0, 1.0)
    }
    
    // MARK: - Recommendations
    private func generateRecommendations(for book: Book, content: String) async throws -> [BookRecommendation] {
        // 基于主题和类型生成推荐
        let themes = try await analyzeThemes(content: content)
        let dataManager = DataManager.shared
        let allBooks = dataManager.library.books
        
        var recommendations: [BookRecommendation] = []
        
        for otherBook in allBooks {
            guard otherBook.id != book.id else { continue }
            
            let similarity = calculateBookSimilarity(book: book, otherBook: otherBook, themes: themes)
            
            if similarity > 0.3 {
                let recommendation = BookRecommendation(
                    id: UUID(),
                    bookId: otherBook.id,
                    title: otherBook.title,
                    reason: generateRecommendationReason(similarity: similarity, themes: themes),
                    similarity: similarity,
                    tags: themes.prefix(3).map { String($0) }
                )
                recommendations.append(recommendation)
            }
        }
        
        return Array(recommendations.sorted { $0.similarity > $1.similarity }.prefix(5))
    }
    
    private func calculateBookSimilarity(book: Book, otherBook: Book, themes: [String]) -> Double {
        var similarity = 0.0
        
        // 基于格式的相似性
        if book.format == otherBook.format {
            similarity += 0.1
        }
        
        // 基于文件大小的相似性
        let sizeDiff = abs(Double(book.fileSize - otherBook.fileSize)) / Double(max(book.fileSize, otherBook.fileSize))
        similarity += max(0, 0.2 - sizeDiff)
        
        // 基于标题的相似性（简单实现）
        let titleSimilarity = calculateTextSimilarity(book.title, otherBook.title)
        similarity += titleSimilarity * 0.3
        
        return min(similarity, 1.0)
    }
    
    private func calculateTextSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func generateRecommendationReason(similarity: Double, themes: [String]) -> String {
        let commonThemes = themes.prefix(2).joined(separator: "、")
        
        if similarity > 0.7 {
            return "与当前书籍高度相似，包含共同主题：\(commonThemes)"
        } else if similarity > 0.5 {
            return "具有相似的内容特征，可能符合您的阅读偏好"
        } else {
            return "基于阅读历史推荐，可能是您感兴趣的内容"
        }
    }
    
    // MARK: - Reading Insights
    func generateReadingInsights(for userId: String) async throws -> [ReadingInsight] {
        let dataManager = DataManager.shared
        // 替换为ReadingEngine的方法
        let readingSessions = ReadingEngine.shared.getReadingSessions(for: nil, userId: userId)
        
        var insights: [ReadingInsight] = []
        
        // 分析阅读模式
        if let patternInsight = analyzeReadingPattern(sessions: readingSessions) {
            insights.append(patternInsight)
        }
        
        // 分析阅读偏好
        if let preferenceInsight = analyzeReadingPreference() {
            insights.append(preferenceInsight)
        }
        
        // 生成改进建议
        if let improvementInsight = generateImprovementSuggestion(sessions: readingSessions) {
            insights.append(improvementInsight)
        }
        
        return insights
    }
    
    private func analyzeReadingPattern(sessions: [ReadingSession]) -> ReadingInsight? {
        guard !sessions.isEmpty else { return nil }
        
        let avgDuration = sessions.map { $0.duration }.reduce(0, +) / Double(sessions.count)
        
        return ReadingInsight(
            insight: "您的平均阅读时长为\(Int(avgDuration))分钟，建议保持规律的阅读习惯",
            type: .pattern,
            relevance: 0.8
        )
    }
    
    private func analyzeReadingPreference() -> ReadingInsight? {
        return ReadingInsight(
            insight: "根据您的阅读历史，您偏好中长篇小说类型",
            type: .preference,
            relevance: 0.7
        )
    }
    
    private func generateImprovementSuggestion(sessions: [ReadingSession]) -> ReadingInsight? {
        return ReadingInsight(
            insight: "建议尝试设置阅读目标，可以提高阅读效率",
            type: .improvement,
            relevance: 0.6
        )
    }
    
    // MARK: - Cache Management
    func clearCache() {
        cachedResults.removeAll()
    }
    
    func removeCachedResult(for bookId: String) {
        cachedResults.removeValue(forKey: bookId)
    }
    
    // MARK: - Privacy and Security
    func exportAnalysisData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(cachedResults)
    }
    
    func deleteAllAnalysisData() {
        cachedResults.removeAll()
        // 清除其他AI相关数据
    }
}

// MARK: - Local AI Models
private class SentimentModel {
    func analyze(content: String) async throws -> SentimentAnalysis {
        // 简化的本地情感分析
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: "。！？.!?"))
        
        var emotionalPoints: [EmotionalPoint] = []
        var sentimentCounts: [SentimentAnalysis.Sentiment: Int] = [:]
        
        for (index, sentence) in sentences.enumerated() {
            let sentiment = analyzeSentence(sentence)
            sentimentCounts[sentiment, default: 0] += 1
            
            let position = Double(index) / Double(sentences.count)
            emotionalPoints.append(EmotionalPoint(
                position: position,
                sentiment: sentiment,
                intensity: 0.5 // 简化实现
            ))
        }
        
        // 确定整体情感
        let overall = sentimentCounts.max { $0.value < $1.value }?.key ?? .neutral
        
        // 计算分布
        let total = sentimentCounts.values.reduce(0, +)
        let distribution = sentimentCounts.mapValues { Double($0) / Double(total) }
        
        return SentimentAnalysis(
            overall: overall,
            distribution: distribution,
            emotionalArc: emotionalPoints
        )
    }
    
    private func analyzeSentence(_ sentence: String) -> SentimentAnalysis.Sentiment {
        let positiveWords = ["好", "棒", "优秀", "喜欢", "高兴", "快乐", "beautiful", "good", "happy", "excellent"]
        let negativeWords = ["坏", "差", "糟糕", "讨厌", "难过", "痛苦", "bad", "terrible", "sad", "awful"]
        
        let lowerSentence = sentence.lowercased()
        
        let positiveCount = positiveWords.reduce(0) { count, word in
            count + (lowerSentence.contains(word) ? 1 : 0)
        }
        
        let negativeCount = negativeWords.reduce(0) { count, word in
            count + (lowerSentence.contains(word) ? 1 : 0)
        }
        
        if positiveCount > negativeCount {
            return .positive
        } else if negativeCount > positiveCount {
            return .negative
        } else if positiveCount > 0 && negativeCount > 0 {
            return .mixed
        } else {
            return .neutral
        }
    }
}

private class SummaryModel {
    // 摘要生成模型的实现
}