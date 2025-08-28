import Foundation
import SwiftUI
import Combine

// MARK: - Reading Session
struct ReadingSession: Identifiable, Codable {
    let id = UUID()
    let bookId: String
    let userId: String
    let startTime: Date
    let endTime: Date
    let startPosition: Int
    let endPosition: Int
    let duration: TimeInterval // 秒
    let wordsRead: Int
    let pagesRead: Int
    
    var readingSpeed: Double { // 每分钟字数
        return duration > 0 ? Double(wordsRead) / (duration / 60.0) : 0
    }
    
    init(bookId: String, userId: String = "default", startTime: Date, endTime: Date, 
         startPosition: Int, endPosition: Int, wordsRead: Int = 0, pagesRead: Int = 0) {
        self.bookId = bookId
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.duration = endTime.timeIntervalSince(startTime)
        self.wordsRead = wordsRead
        self.pagesRead = pagesRead
    }
}

// MARK: - Reading Progress
struct ReadingProgress: Codable {
    let bookId: String
    var currentPosition: Int
    var currentPage: Int
    var totalPages: Int
    var progressPercentage: Double
    var lastReadAt: Date
    var totalReadingTime: TimeInterval
    var sessionCount: Int
    
    init(bookId: String, currentPosition: Int = 0, currentPage: Int = 0, totalPages: Int = 1) {
        self.bookId = bookId
        self.currentPosition = currentPosition
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.progressPercentage = totalPages > 0 ? Double(currentPage) / Double(totalPages) : 0
        self.lastReadAt = Date()
        self.totalReadingTime = 0
        self.sessionCount = 0
    }
}

// MARK: - Page
struct Page {
    let number: Int
    let content: String
    let startPosition: Int
    let endPosition: Int
    let wordCount: Int
    
    init(number: Int, content: String, startPosition: Int, endPosition: Int) {
        self.number = number
        self.content = content
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.wordCount = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
}

// MARK: - Reading Statistics
struct ReadingStatistics {
    let totalBooksRead: Int
    let totalReadingTime: TimeInterval
    let averageReadingSpeed: Double // 每分钟字数
    let totalWordsRead: Int
    let currentStreak: Int // 连续阅读天数
    let longestStreak: Int
    let favoriteReadingTime: (hour: Int, duration: TimeInterval)
    let dailyGoalProgress: Double
    let weeklyGoalProgress: Double
}

// MARK: - Reading Engine
@MainActor
class ReadingEngine: ObservableObject {
    static let shared = ReadingEngine()
    
    @Published var currentSession: ReadingSession?
    @Published var currentProgress: ReadingProgress?
    @Published var pages: [Page] = []
    @Published var currentPageIndex = 0
    @Published var isReading = false
    
    private var readingSessions: [ReadingSession] = []
    private var progressData: [String: ReadingProgress] = [:]
    private var sessionStartTime: Date?
    private var sessionStartPosition: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadReadingSessions()
        loadProgressData()
    }
    
    // MARK: - Page Management
    func calculatePages(content: String, pageSize: CGSize, fontSize: Double) -> [Page] {
        let estimatedCharsPerPage = Int(pageSize.width * pageSize.height / (fontSize * fontSize / 2))
        let lines = content.components(separatedBy: .newlines)
        
        var pages: [Page] = []
        var currentPageContent = ""
        var currentPageStartPosition = 0
        var currentPosition = 0
        var pageNumber = 1
        
        for line in lines {
            let lineWithNewline = line + "\n"
            
            // 检查是否超过页面容量
            if currentPageContent.count + lineWithNewline.count > estimatedCharsPerPage && !currentPageContent.isEmpty {
                // 创建当前页
                let page = Page(
                    number: pageNumber,
                    content: currentPageContent.trimmingCharacters(in: .whitespacesAndNewlines),
                    startPosition: currentPageStartPosition,
                    endPosition: currentPosition
                )
                pages.append(page)
                
                // 开始新页
                pageNumber += 1
                currentPageContent = lineWithNewline
                currentPageStartPosition = currentPosition
            } else {
                currentPageContent += lineWithNewline
            }
            
            currentPosition += lineWithNewline.count
        }
        
        // 添加最后一页
        if !currentPageContent.isEmpty {
            let page = Page(
                number: pageNumber,
                content: currentPageContent.trimmingCharacters(in: .whitespacesAndNewlines),
                startPosition: currentPageStartPosition,
                endPosition: currentPosition
            )
            pages.append(page)
        }
        
        self.pages = pages
        return pages
    }
    
    func getCurrentPage() -> Page? {
        guard currentPageIndex >= 0 && currentPageIndex < pages.count else { return nil }
        return pages[currentPageIndex]
    }
    
    func getPageAt(index: Int) -> Page? {
        guard index >= 0 && index < pages.count else { return nil }
        return pages[index]
    }
    
    func goToPage(_ pageNumber: Int) {
        let index = pageNumber - 1
        guard index >= 0 && index < pages.count else { return }
        currentPageIndex = index
        updateReadingProgress()
    }
    
    func nextPage() -> Bool {
        guard currentPageIndex < pages.count - 1 else { return false }
        currentPageIndex += 1
        updateReadingProgress()
        return true
    }
    
    func previousPage() -> Bool {
        guard currentPageIndex > 0 else { return false }
        currentPageIndex -= 1
        updateReadingProgress()
        return true
    }
    
    // MARK: - Reading Session Management
    func startReadingSession(bookId: String, position: Int = 0) {
        sessionStartTime = Date()
        sessionStartPosition = position
        isReading = true
        
        // 加载或创建进度
        if let existingProgress = progressData[bookId] {
            currentProgress = existingProgress
        } else {
            currentProgress = ReadingProgress(bookId: bookId, currentPosition: position)
            progressData[bookId] = currentProgress
        }
        
        saveProgressData()
    }
    
    func endReadingSession() {
        guard let startTime = sessionStartTime,
              let progress = currentProgress else { return }
        
        let endTime = Date()
        let currentPosition = getCurrentPosition()
        
        let session = ReadingSession(
            bookId: progress.bookId,
            startTime: startTime,
            endTime: endTime,
            startPosition: sessionStartPosition,
            endPosition: currentPosition,
            wordsRead: calculateWordsRead(from: sessionStartPosition, to: currentPosition),
            pagesRead: max(0, currentPageIndex - getPageIndex(for: sessionStartPosition))
        )
        
        readingSessions.append(session)
        saveReadingSessions()
        
        // 更新总阅读时间
        if var updatedProgress = currentProgress {
            updatedProgress.totalReadingTime += session.duration
            updatedProgress.sessionCount += 1
            updatedProgress.lastReadAt = endTime
            currentProgress = updatedProgress
            progressData[progress.bookId] = updatedProgress
        }
        
        saveProgressData()
        
        sessionStartTime = nil
        sessionStartPosition = 0
        isReading = false
        currentSession = session
    }
    
    func pauseReading() {
        if isReading {
            endReadingSession()
        }
    }
    
    func resumeReading(bookId: String) {
        if let progress = progressData[bookId] {
            startReadingSession(bookId: bookId, position: progress.currentPosition)
        }
    }
    
    // MARK: - Progress Management
    func updateReadingProgress() {
        guard var progress = currentProgress else { return }
        
        let currentPosition = getCurrentPosition()
        let currentPage = currentPageIndex + 1
        
        progress.currentPosition = currentPosition
        progress.currentPage = currentPage
        progress.progressPercentage = Double(currentPage) / Double(max(1, pages.count))
        progress.lastReadAt = Date()
        
        currentProgress = progress
        progressData[progress.bookId] = progress
        
        // 自动保存进度
        saveProgressData()
        
        // 更新DataManager中的书籍进度
        Task {
            DataManager.shared.saveReadingProgress(progress)
        }
    }
    
    func getReadingProgress(for bookId: String) -> Double {
        return progressData[bookId]?.progressPercentage ?? 0.0
    }
    
    func setReadingProgress(for bookId: String, progress: Double) {
        if var existingProgress = progressData[bookId] {
            let totalPages = existingProgress.totalPages
            let newPage = max(1, min(totalPages, Int(ceil(progress * Double(totalPages)))))
            
            existingProgress.progressPercentage = progress
            existingProgress.currentPage = newPage
            existingProgress.lastReadAt = Date()
            
            progressData[bookId] = existingProgress
            saveProgressData()
        }
    }
    
    // MARK: - Position Calculations
    private func getCurrentPosition() -> Int {
        guard let currentPage = getCurrentPage() else { return 0 }
        return currentPage.startPosition
    }
    
    private func getPageIndex(for position: Int) -> Int {
        for (index, page) in pages.enumerated() {
            if position >= page.startPosition && position <= page.endPosition {
                return index
            }
        }
        return 0
    }
    
    private func calculateWordsRead(from startPosition: Int, to endPosition: Int) -> Int {
        let startPageIndex = getPageIndex(for: startPosition)
        let endPageIndex = getPageIndex(for: endPosition)
        
        var wordsRead = 0
        for i in startPageIndex...min(endPageIndex, pages.count - 1) {
            wordsRead += pages[i].wordCount
        }
        
        return wordsRead
    }
    
    // MARK: - Reading Statistics
    func getReadingStatistics(for userId: String = "default") -> ReadingStatistics {
        let userSessions = readingSessions.filter { $0.userId == userId }
        
        let totalBooksRead = Set(userSessions.map { $0.bookId }).count
        let totalReadingTime = userSessions.reduce(0) { $0 + $1.duration }
        let totalWordsRead = userSessions.reduce(0) { $0 + $1.wordsRead }
        let averageSpeed = totalReadingTime > 0 ? Double(totalWordsRead) / (totalReadingTime / 60.0) : 0
        
        // 计算连续阅读天数
        let (currentStreak, longestStreak) = calculateReadingStreaks(sessions: userSessions)
        
        // 计算最喜欢的阅读时间
        let favoriteTime = calculateFavoriteReadingTime(sessions: userSessions)
        
        return ReadingStatistics(
            totalBooksRead: totalBooksRead,
            totalReadingTime: totalReadingTime,
            averageReadingSpeed: averageSpeed,
            totalWordsRead: totalWordsRead,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            favoriteReadingTime: favoriteTime,
            dailyGoalProgress: 0.0, // TODO: 实现目标功能
            weeklyGoalProgress: 0.0  // TODO: 实现目标功能
        )
    }
    
    private func calculateReadingStreaks(sessions: [ReadingSession]) -> (current: Int, longest: Int) {
        let calendar = Calendar.current
        let sessionDates = Set(sessions.map { calendar.startOfDay(for: $0.startTime) })
        let sortedDates = sessionDates.sorted()
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        
        let today = calendar.startOfDay(for: Date())
        var currentDate = today
        
        // 计算当前连续天数
        while sessionDates.contains(currentDate) {
            currentStreak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        // 计算最长连续天数
        var previousDate: Date?
        for date in sortedDates {
            if let prev = previousDate {
                let daysDifference = calendar.dateComponents([.day], from: prev, to: date).day ?? 0
                if daysDifference == 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            previousDate = date
        }
        longestStreak = max(longestStreak, tempStreak)
        
        return (currentStreak, longestStreak)
    }
    
    private func calculateFavoriteReadingTime(sessions: [ReadingSession]) -> (hour: Int, duration: TimeInterval) {
        let calendar = Calendar.current
        var hourlyDurations: [Int: TimeInterval] = [:]
        
        for session in sessions {
            let hour = calendar.component(.hour, from: session.startTime)
            hourlyDurations[hour, default: 0] += session.duration
        }
        
        let favoriteHour = hourlyDurations.max { $0.value < $1.value }
        return (hour: favoriteHour?.key ?? 0, duration: favoriteHour?.value ?? 0)
    }
    
    // MARK: - Session Queries
    func getReadingSessions(for bookId: String? = nil, userId: String = "default") -> [ReadingSession] {
        var sessions = readingSessions.filter { $0.userId == userId }
        
        if let bookId = bookId {
            sessions = sessions.filter { $0.bookId == bookId }
        }
        
        return sessions.sorted { $0.startTime > $1.startTime }
    }
    
    func getTodaysSessions(userId: String = "default") -> [ReadingSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return readingSessions.filter { session in
            session.userId == userId &&
            session.startTime >= today &&
            session.startTime < tomorrow
        }
    }
    
    func getWeekSessions(userId: String = "default") -> [ReadingSession] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        
        return readingSessions.filter { session in
            session.userId == userId && session.startTime >= weekAgo
        }
    }
    
    // MARK: - Data Management
    func saveReadingSession(_ session: ReadingSession) async {
        readingSessions.append(session)
        saveReadingSessions()
    }
    
    func deleteSession(_ session: ReadingSession) {
        readingSessions.removeAll { $0.id == session.id }
        saveReadingSessions()
    }
    
    func clearAllSessions() {
        readingSessions.removeAll()
        saveReadingSessions()
    }
    
    // MARK: - Persistence
    private func saveReadingSessions() {
        do {
            let data = try JSONEncoder().encode(readingSessions)
            userDefaults.set(data, forKey: "reading_sessions")
        } catch {
            print("保存阅读会话失败: \(error)")
        }
    }
    
    private func loadReadingSessions() {
        guard let data = userDefaults.data(forKey: "reading_sessions") else { return }
        
        do {
            readingSessions = try JSONDecoder().decode([ReadingSession].self, from: data)
        } catch {
            print("加载阅读会话失败: \(error)")
        }
    }
    
    private func saveProgressData() {
        do {
            let data = try JSONEncoder().encode(progressData)
            userDefaults.set(data, forKey: "reading_progress")
        } catch {
            print("保存阅读进度失败: \(error)")
        }
    }
    
    private func loadProgressData() {
        guard let data = userDefaults.data(forKey: "reading_progress") else { return }
        
        do {
            progressData = try JSONDecoder().decode([String: ReadingProgress].self, from: data)
        } catch {
            print("加载阅读进度失败: \(error)")
        }
    }
}

// MARK: - Array Extension
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        return Array(Set(self))
    }
}