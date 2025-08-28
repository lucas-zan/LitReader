import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var readingEngine: ReadingEngine
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var readingStats: ReadingStatistics?
    @State private var dailyReadingData: [DailyReading] = []
    @State private var bookProgressData: [BookProgress] = []
    @State private var showingDetailedStats = false
    
    enum TimeRange: String, CaseIterable {
        case week = "本周"
        case month = "本月"
        case year = "今年"
        case all = "全部"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 时间范围选择器
                timeRangeSelector
                
                // 总体统计卡片
                overallStatsSection
                
                // 阅读趋势图表
                readingTrendsChart
                
                // 书籍进度统计
                bookProgressSection
                
                // 阅读习惯分析
                readingHabitsSection
                
                // 成就与目标
                achievementsSection
            }
            .padding()
        }
        .navigationTitle("阅读统计")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingDetailedStats = true
                } label: {
                    Image(systemName: "chart.bar.doc.horizontal")
                }
            }
        }
        .onAppear {
            loadStatistics()
        }
        .onChange(of: selectedTimeRange) { _ in
            loadStatistics()
        }
        .sheet(isPresented: $showingDetailedStats) {
            DetailedStatisticsView()
        }
    }
    
    // MARK: - 时间范围选择器
    private var timeRangeSelector: some View {
        Picker("时间范围", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    // MARK: - 总体统计部分
    private var overallStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("总体统计")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textUIColor)
            
            if let stats = readingStats {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatsCard(
                        title: "阅读时长",
                        value: formatReadingTime(stats.totalReadingTime),
                        subtitle: selectedTimeRange.rawValue,
                        icon: "clock",
                        color: .blue
                    )
                    
                    StatsCard(
                        title: "阅读书籍",
                        value: "\(stats.totalBooksRead)",
                        subtitle: "本",
                        icon: "book.closed",
                        color: .green
                    )
                    
                    StatsCard(
                        title: "阅读字数",
                        value: formatLargeNumber(stats.totalWordsRead),
                        subtitle: "字",
                        icon: "doc.text",
                        color: .orange
                    )
                    
                    StatsCard(
                        title: "阅读速度",
                        value: "\(Int(stats.averageReadingSpeed))",
                        subtitle: "字/分钟",
                        icon: "speedometer",
                        color: .purple
                    )
                }
            } else {
                ProgressView("加载统计数据...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
    }
    
    // MARK: - 阅读趋势图表
    private var readingTrendsChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("阅读趋势")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textUIColor)
            
            VStack(spacing: 12) {
                // 图表
                if !dailyReadingData.isEmpty {
                    Chart(dailyReadingData) { item in
                        LineMark(
                            x: .value("日期", item.date),
                            y: .value("阅读时长", item.readingMinutes)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("日期", item.date),
                            y: .value("阅读时长", item.readingMinutes)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 200)
                    .chartYAxisLabel("分钟")
                    .chartXAxisLabel("日期")
                } else {
                    Text("暂无数据")
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                }
                
                // 图表说明
                HStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    Text("每日阅读时长")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let avgTime = calculateAverageReadingTime() {
                        Text("平均: \(avgTime)分钟/天")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 书籍进度统计
    private var bookProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("书籍进度")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textUIColor)
            
            VStack(spacing: 12) {
                if !bookProgressData.isEmpty {
                    ForEach(bookProgressData.prefix(5)) { book in
                        BookProgressRow(bookProgress: book)
                    }
                    
                    if bookProgressData.count > 5 {
                        Button {
                            // TODO: 显示更多书籍进度
                        } label: {
                            Text("查看更多 (\(bookProgressData.count - 5) 本)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Text("暂无阅读记录")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 阅读习惯分析
    private var readingHabitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("阅读习惯")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textUIColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                HabitCard(
                    title: "最爱时段",
                    value: readingStats?.favoriteReadingTime.hour.description ?? "0",
                    unit: "点",
                    icon: "clock.arrow.circlepath",
                    color: .indigo
                )
                
                HabitCard(
                    title: "连续天数",
                    value: "\(readingStats?.currentStreak ?? 0)",
                    unit: "天",
                    icon: "flame",
                    color: .red
                )
                
                HabitCard(
                    title: "最长连续",
                    value: "\(readingStats?.longestStreak ?? 0)",
                    unit: "天",
                    icon: "calendar",
                    color: .cyan
                )
                
                HabitCard(
                    title: "今日目标",
                    value: "\(Int((readingStats?.dailyGoalProgress ?? 0) * 100))",
                    unit: "%",
                    icon: "target",
                    color: .mint
                )
            }
        }
    }
    
    // MARK: - 成就与目标
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("成就与目标")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textUIColor)
                
                Spacer()
                
                Button("查看全部") {
                    // TODO: 跳转到成就页面
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AchievementBadge(
                        title: "阅读新手",
                        icon: "book.closed",
                        isUnlocked: (readingStats?.totalBooksRead ?? 0) > 0,
                        progress: min(1.0, Double(readingStats?.totalBooksRead ?? 0) / 1.0)
                    )
                    
                    AchievementBadge(
                        title: "坚持阅读",
                        icon: "flame",
                        isUnlocked: (readingStats?.currentStreak ?? 0) >= 7,
                        progress: min(1.0, Double(readingStats?.currentStreak ?? 0) / 7.0)
                    )
                    
                    AchievementBadge(
                        title: "速度达人",
                        icon: "speedometer",
                        isUnlocked: (readingStats?.averageReadingSpeed ?? 0) >= 300,
                        progress: min(1.0, (readingStats?.averageReadingSpeed ?? 0) / 300.0)
                    )
                    
                    AchievementBadge(
                        title: "时间达人",
                        icon: "clock",
                        isUnlocked: (readingStats?.totalReadingTime ?? 0) >= 3600, // 1小时
                        progress: min(1.0, (readingStats?.totalReadingTime ?? 0) / 3600.0)
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 辅助方法
    private func loadStatistics() {
        readingStats = readingEngine.getReadingStatistics()
        loadDailyReadingData()
        loadBookProgressData()
    }
    
    private func loadDailyReadingData() {
        let calendar = Calendar.current
        let now = Date()
        
        var days: Int
        switch selectedTimeRange {
        case .week:
            days = 7
        case .month:
            days = 30
        case .year:
            days = 365
        case .all:
            days = 365 * 2 // 最多显示2年
        }
        
        dailyReadingData = []
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                let sessions = readingEngine.getReadingSessions().filter { session in
                    calendar.isDate(session.startTime, inSameDayAs: date)
                }
                
                let totalMinutes = sessions.reduce(0) { $0 + $1.duration / 60 }
                
                dailyReadingData.append(DailyReading(
                    date: date,
                    readingMinutes: Int(totalMinutes)
                ))
            }
        }
        
        dailyReadingData.reverse() // 按时间正序排列
    }
    
    private func loadBookProgressData() {
        let books = dataManager.library.books
        bookProgressData = books.map { book in
            BookProgress(
                id: book.id,
                title: book.title,
                author: book.author,
                progress: book.progress,
                lastReadAt: book.lastReadAt
            )
        }
        .sorted { book1, book2 in
            (book1.lastReadAt ?? Date.distantPast) > (book2.lastReadAt ?? Date.distantPast)
        }
    }
    
    private func calculateAverageReadingTime() -> Int? {
        guard !dailyReadingData.isEmpty else { return nil }
        let total = dailyReadingData.reduce(0) { $0 + $1.readingMinutes }
        return total / dailyReadingData.count
    }
    
    private func formatReadingTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatLargeNumber(_ number: Int) -> String {
        if number >= 10000 {
            return String(format: "%.1f万", Double(number) / 10000)
        } else if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000)
        } else {
            return "\(number)"
        }
    }
}

// MARK: - 数据模型
struct DailyReading: Identifiable {
    let id = UUID()
    let date: Date
    let readingMinutes: Int
}

struct BookProgress: Identifiable {
    let id: String
    let title: String
    let author: String?
    let progress: Double
    let lastReadAt: Date?
}

// MARK: - 辅助视图组件
struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct HabitCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct BookProgressRow: View {
    let bookProgress: BookProgress
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bookProgress.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let author = bookProgress.author {
                    Text(author)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(bookProgress.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let lastRead = bookProgress.lastReadAt {
                    Text(formatRelativeDate(lastRead))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 详细统计视图
struct DetailedStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("详细统计功能正在开发中...")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle("详细统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatisticsView()
        }
        .environmentObject(ReadingEngine.shared)
        .environmentObject(DataManager.shared)
        .environmentObject(ThemeManager.shared)
    }
}