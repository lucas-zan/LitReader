import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var readingEngine: ReadingEngine
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navigationSystem: NavigationSystem
    @EnvironmentObject var cloudSync: CloudSync
    
    @State private var readingStats: ReadingStatistics?
    @State private var userProfile = UserProfile.default
    @State private var showingEditProfile = false
    @State private var showingAchievements = false
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 用户头像和基本信息
                profileHeaderSection
                
                // 阅读统计卡片
                readingStatsSection
                
                // 成就系统
                achievementsSection
                
                // 阅读目标
                readingGoalsSection
                
                // 个人设置
                settingsSection
            }
            .padding()
        }
        .navigationTitle("个人中心")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditProfile = true
                } label: {
                    Text("编辑")
                }
            }
        }
        .onAppear {
            loadReadingStatistics()
            loadUserProfile()
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userProfile: $userProfile)
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView()
        }
    }
    
    // MARK: - 用户头像和基本信息
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                if let avatarURL = userProfile.avatarURL,
                   let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Text(userProfile.displayName.prefix(1).uppercased())
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(spacing: 4) {
                Text(userProfile.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textUIColor)
                
                if !userProfile.bio.isEmpty {
                    Text(userProfile.bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 16) {
                    if let readingStats = readingStats {
                        ProfileStatItem(
                            title: "已读书籍",
                            value: "\(readingStats.totalBooksRead)",
                            icon: "book.closed"
                        )
                        
                        ProfileStatItem(
                            title: "阅读时长",
                            value: formatReadingTime(readingStats.totalReadingTime),
                            icon: "clock"
                        )
                        
                        ProfileStatItem(
                            title: "连续天数",
                            value: "\(readingStats.currentStreak)",
                            icon: "flame"
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - 阅读统计部分
    private var readingStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("阅读统计")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textUIColor)
                
                Spacer()
                
                Button {
                    Task {
                        try? await navigationSystem.navigate(to: .statistics)
                    }
                } label: {
                    Text("查看详情")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if let stats = readingStats {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatisticCard(
                        title: "总阅读字数",
                        value: formatLargeNumber(stats.totalWordsRead),
                        icon: "doc.text",
                        color: .blue
                    )
                    
                    StatisticCard(
                        title: "平均阅读速度",
                        value: "\(Int(stats.averageReadingSpeed))字/分",
                        icon: "speedometer",
                        color: .green
                    )
                    
                    StatisticCard(
                        title: "最长连续",
                        value: "\(stats.longestStreak)天",
                        icon: "calendar",
                        color: .orange
                    )
                    
                    StatisticCard(
                        title: "喜爱时段",
                        value: "\(stats.favoriteReadingTime.hour):00",
                        icon: "clock.arrow.circlepath",
                        color: .purple
                    )
                }
            } else {
                ProgressView("加载统计数据...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
    }
    
    // MARK: - 成就系统部分
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("成就系统")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textUIColor)
                
                Spacer()
                
                Button {
                    showingAchievements = true
                } label: {
                    Text("查看全部")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 模拟一些成就
                    AchievementBadge(
                        title: "阅读新手",
                        icon: "book.closed",
                        isUnlocked: true,
                        progress: 1.0
                    )
                    
                    AchievementBadge(
                        title: "专注读者",
                        icon: "flame",
                        isUnlocked: (readingStats?.currentStreak ?? 0) >= 7,
                        progress: min(1.0, Double(readingStats?.currentStreak ?? 0) / 7.0)
                    )
                    
                    AchievementBadge(
                        title: "书虫",
                        icon: "books.vertical",
                        isUnlocked: (readingStats?.totalBooksRead ?? 0) >= 100,
                        progress: min(1.0, Double(readingStats?.totalBooksRead ?? 0) / 100.0)
                    )
                    
                    AchievementBadge(
                        title: "马拉松读者",
                        icon: "stopwatch",
                        isUnlocked: false,
                        progress: 0.6
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 阅读目标部分
    private var readingGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("阅读目标")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textUIColor)
            
            VStack(spacing: 12) {
                // 每日目标
                GoalProgressView(
                    title: "每日阅读",
                    current: userProfile.dailyReadingGoal.currentMinutes,
                    target: userProfile.dailyReadingGoal.targetMinutes,
                    unit: "分钟",
                    color: .blue,
                    icon: "clock"
                )
                
                // 每周目标
                GoalProgressView(
                    title: "每周阅读",
                    current: userProfile.weeklyReadingGoal.currentBooks,
                    target: userProfile.weeklyReadingGoal.targetBooks,
                    unit: "本书",
                    color: .green,
                    icon: "book"
                )
                
                // 每月目标
                GoalProgressView(
                    title: "每月阅读",
                    current: userProfile.monthlyReadingGoal.currentBooks,
                    target: userProfile.monthlyReadingGoal.targetBooks,
                    unit: "本书",
                    color: .orange,
                    icon: "calendar"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 设置部分
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("个人设置")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textUIColor)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "gear",
                    title: "应用设置",
                    action: {
                        Task {
                            try? await navigationSystem.navigate(to: .settings)
                        }
                    }
                )
                
                Divider()
                
                SettingsRow(
                    icon: "paintbrush",
                    title: "主题设置",
                    action: {
                        Task {
                            try? await navigationSystem.navigate(to: .themes)
                        }
                    }
                )
                
                Divider()
                
                SettingsRow(
                    icon: "icloud",
                    title: "云同步",
                    subtitle: cloudSync.isEnabled ? "已启用" : "已禁用",
                    action: {
                        // TODO: 云同步设置
                    }
                )
                
                Divider()
                
                SettingsRow(
                    icon: "square.and.arrow.up",
                    title: "导出数据",
                    action: {
                        exportUserData()
                    }
                )
                
                Divider()
                
                SettingsRow(
                    icon: "questionmark.circle",
                    title: "帮助与支持",
                    action: {
                        Task {
                            try? await navigationSystem.navigate(to: .help)
                        }
                    }
                )
                
                Divider()
                
                SettingsRow(
                    icon: "info.circle",
                    title: "关于应用",
                    action: {
                        Task {
                            try? await navigationSystem.navigate(to: .about)
                        }
                    }
                )
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 辅助方法
    private func loadReadingStatistics() {
        readingStats = readingEngine.getReadingStatistics()
    }
    
    private func loadUserProfile() {
        // TODO: 从存储中加载用户资料
    }
    
    private func exportUserData() {
        // TODO: 实现数据导出功能
    }
    
    private func formatReadingTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        if hours > 0 {
            return "\(hours)小时"
        } else {
            let minutes = Int(seconds) / 60
            return "\(minutes)分钟"
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

// MARK: - 用户资料数据模型
struct UserProfile {
    var displayName: String
    var bio: String
    var avatarURL: String?
    var joinDate: Date
    var dailyReadingGoal: DailyGoal
    var weeklyReadingGoal: WeeklyGoal
    var monthlyReadingGoal: MonthlyGoal
    
    struct DailyGoal {
        var targetMinutes: Int
        var currentMinutes: Int
    }
    
    struct WeeklyGoal {
        var targetBooks: Int
        var currentBooks: Int
    }
    
    struct MonthlyGoal {
        var targetBooks: Int
        var currentBooks: Int
    }
    
    static let `default` = UserProfile(
        displayName: "阅读爱好者",
        bio: "热爱阅读，享受文字的魅力",
        avatarURL: nil,
        joinDate: Date(),
        dailyReadingGoal: DailyGoal(targetMinutes: 30, currentMinutes: 15),
        weeklyReadingGoal: WeeklyGoal(targetBooks: 2, currentBooks: 1),
        monthlyReadingGoal: MonthlyGoal(targetBooks: 8, currentBooks: 3)
    )
}

// MARK: - 辅助视图组件
struct ProfileStatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct AchievementBadge: View {
    let title: String
    let icon: String
    let isUnlocked: Bool
    let progress: Double
    let description: String?  // 添加description参数
    
    init(title: String, icon: String, isUnlocked: Bool, progress: Double, description: String? = nil) {
        self.title = title
        self.icon = icon
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.description = description
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(isUnlocked ? Color.yellow : Color.gray, lineWidth: 2)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? .yellow : .gray)
                
                if !isUnlocked && progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(isUnlocked ? .primary : .secondary)
        }
        .frame(width: 70)
    }
}

struct GoalProgressView: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let color: Color
    let icon: String
    
    private var progress: Double {
        target > 0 ? min(1.0, Double(current) / Double(target)) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(current)/\(target) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
            
            HStack {
                Text("进度: \(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if current >= target {
                    Text("已完成")
                        .font(.caption)
                        .foregroundColor(color)
                        .fontWeight(.medium)
                } else {
                    Text("还需 \(target - current) \(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 编辑个人资料视图
struct EditProfileView: View {
    @Binding var userProfile: UserProfile
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempProfile: UserProfile
    
    init(userProfile: Binding<UserProfile>) {
        self._userProfile = userProfile
        self._tempProfile = State(initialValue: userProfile.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("昵称", text: $tempProfile.displayName)
                    TextField("个人简介", text: $tempProfile.bio, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section("阅读目标") {
                    HStack {
                        Text("每日阅读时长")
                        Spacer()
                        TextField("分钟", value: $tempProfile.dailyReadingGoal.targetMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("分钟")
                    }
                    
                    HStack {
                        Text("每周阅读书籍")
                        Spacer()
                        TextField("本", value: $tempProfile.weeklyReadingGoal.targetBooks, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("本")
                    }
                    
                    HStack {
                        Text("每月阅读书籍")
                        Spacer()
                        TextField("本", value: $tempProfile.monthlyReadingGoal.targetBooks, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("本")
                    }
                }
            }
            .navigationTitle("编辑个人资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        userProfile = tempProfile
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 成就详情视图
struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // TODO: 实现完整的成就系统
                Text("成就系统正在开发中...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("成就系统")
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
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
        .environmentObject(DataManager.shared)
        .environmentObject(ReadingEngine.shared)
        .environmentObject(ThemeManager.shared)
        .environmentObject(NavigationSystem.shared)
        .environmentObject(CloudSync.shared)
    }
}