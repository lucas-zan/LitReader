import SwiftUI

struct HelpView: View {
    @EnvironmentObject var navigationSystem: NavigationSystem
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory = .all
    @State private var expandedFAQs = Set<UUID>()
    
    enum HelpCategory: String, CaseIterable {
        case all = "全部"
        case reading = "阅读功能"
        case bookmarks = "书签管理"
        case importing = "文件导入"
        case sync = "云同步"
        case settings = "设置选项"
        case troubleshooting = "故障排除"
    }
    
    var filteredFAQs: [FAQ] {
        let categoryFiltered = selectedCategory == .all ? faqs : faqs.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { faq in
                faq.question.localizedCaseInsensitiveContains(searchText) ||
                faq.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            searchSection
            
            // 分类选择器
            categoryPicker
            
            // 快速帮助卡片
            if selectedCategory == .all && searchText.isEmpty {
                quickHelpSection
            }
            
            // FAQ列表
            faqSection
        }
        .navigationTitle("帮助与支持")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        openUserGuide()
                    } label: {
                        Label("用户指南", systemImage: "book")
                    }
                    
                    Button {
                        openVideoTutorials()
                    } label: {
                        Label("视频教程", systemImage: "play.rectangle")
                    }
                    
                    Button {
                        contactSupport()
                    } label: {
                        Label("联系客服", systemImage: "message")
                    }
                    
                    Button {
                        reportBug()
                    } label: {
                        Label("反馈问题", systemImage: "exclamationmark.bubble")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    // MARK: - 搜索部分
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索帮助内容...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - 分类选择器
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HelpCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedCategory == category ? Color.blue : Color(.systemGray5)
                            )
                            .foregroundColor(
                                selectedCategory == category ? .white : .primary
                            )
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 快速帮助部分
    private var quickHelpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快速帮助")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickHelpCard(
                    icon: "plus.circle",
                    title: "导入书籍",
                    description: "了解如何添加和导入书籍文件",
                    action: {
                        selectedCategory = .importing
                    }
                )
                
                QuickHelpCard(
                    icon: "book.open",
                    title: "阅读技巧",
                    description: "掌握各种阅读功能和快捷操作",
                    action: {
                        selectedCategory = .reading
                    }
                )
                
                QuickHelpCard(
                    icon: "bookmark",
                    title: "书签管理",
                    description: "学习如何有效管理和使用书签",
                    action: {
                        selectedCategory = .bookmarks
                    }
                )
                
                QuickHelpCard(
                    icon: "icloud",
                    title: "云端同步",
                    description: "设置和使用云同步功能",
                    action: {
                        selectedCategory = .sync
                    }
                )
                
                QuickHelpCard(
                    icon: "gear",
                    title: "个性设置",
                    description: "个性化你的阅读体验",
                    action: {
                        selectedCategory = .settings
                    }
                )
                
                QuickHelpCard(
                    icon: "wrench",
                    title: "故障排除",
                    description: "解决常见问题和故障",
                    action: {
                        selectedCategory = .troubleshooting
                    }
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - FAQ部分
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !filteredFAQs.isEmpty {
                HStack {
                    Text("常见问题")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(filteredFAQs.count) 个问题")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                List {
                    ForEach(filteredFAQs) { faq in
                        FAQRow(
                            faq: faq,
                            isExpanded: expandedFAQs.contains(faq.id),
                            onToggle: {
                                withAnimation {
                                    if expandedFAQs.contains(faq.id) {
                                        expandedFAQs.remove(faq.id)
                                    } else {
                                        expandedFAQs.insert(faq.id)
                                    }
                                }
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                emptyResultsView
            }
        }
    }
    
    // MARK: - 空结果视图
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("没有找到相关帮助")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("尝试使用不同的关键词或选择其他分类")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                contactSupport()
            } label: {
                Text("联系客服")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - 辅助方法
    private func openUserGuide() {
        // TODO: 打开用户指南
    }
    
    private func openVideoTutorials() {
        // TODO: 打开视频教程
    }
    
    private func contactSupport() {
        if let emailURL = URL(string: "mailto:support@litreader.com?subject=LitReader帮助咨询") {
            UIApplication.shared.open(emailURL)
        }
    }
    
    private func reportBug() {
        if let emailURL = URL(string: "mailto:support@litreader.com?subject=LitReader问题反馈") {
            UIApplication.shared.open(emailURL)
        }
    }
}

// MARK: - FAQ数据模型
struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let category: HelpView.HelpCategory
    let tags: [String]
}

// MARK: - FAQ数据
private let faqs: [FAQ] = [
    // 阅读功能
    FAQ(
        question: "如何翻页？",
        answer: "您可以通过以下方式翻页：\n• 点击屏幕左侧或右侧区域\n• 左右滑动手势\n• 使用音量键（需在设置中开启）\n• 双击屏幕中央打开翻页菜单",
        category: .reading,
        tags: ["翻页", "手势", "操作"]
    ),
    
    FAQ(
        question: "如何调整字体大小？",
        answer: "您可以在阅读界面调整字体：\n• 点击屏幕中央，在弹出的工具栏中选择字体图标\n• 使用捏合手势放大或缩小\n• 在设置页面中进行详细调整\n• 选择不同的预设主题",
        category: .reading,
        tags: ["字体", "大小", "设置"]
    ),
    
    FAQ(
        question: "如何更换阅读主题？",
        answer: "更换阅读主题的方法：\n• 在阅读界面点击屏幕中央，选择主题图标\n• 前往设置 → 主题设置\n• 选择预设主题或创建自定义主题\n• 支持日间、夜间、护眼等多种模式",
        category: .reading,
        tags: ["主题", "外观", "护眼"]
    ),
    
    // 书签管理
    FAQ(
        question: "如何添加书签？",
        answer: "添加书签的方法：\n• 在阅读页面长按文本选择添加书签\n• 点击屏幕中央，在工具栏中选择书签图标\n• 可以为书签添加标题和备注\n• 支持书签分类管理",
        category: .bookmarks,
        tags: ["书签", "添加", "管理"]
    ),
    
    FAQ(
        question: "如何管理书签分类？",
        answer: "书签分类管理：\n• 在书签页面点击管理分类\n• 可以创建、删除、重命名分类\n• 将书签拖拽到不同分类\n• 支持按分类筛选和搜索书签",
        category: .bookmarks,
        tags: ["分类", "管理", "整理"]
    ),
    
    // 文件导入
    FAQ(
        question: "支持哪些文件格式？",
        answer: "LitReader支持以下格式：\n• TXT文本文件\n• EPUB电子书格式\n• PDF文档（实验性支持）\n• 未来将支持更多格式",
        category: .importing,
        tags: ["格式", "支持", "文件"]
    ),
    
    FAQ(
        question: "如何导入书籍？",
        answer: "导入书籍的方法：\n• 使用<文件>应用选择文件\n• 通过AirDrop接收文件\n• 从其他应用分享到LitReader\n• 通过iTunes文件共享\n• 从云存储服务导入",
        category: .importing,
        tags: ["导入", "文件", "方法"]
    ),
    
    // 云同步
    FAQ(
        question: "如何启用云同步？",
        answer: "启用云同步：\n• 确保已登录iCloud账户\n• 前往设置 → 云同步\n• 开启同步功能\n• 选择要同步的数据类型\n• 首次同步可能需要一些时间",
        category: .sync,
        tags: ["云同步", "iCloud", "设置"]
    ),
    
    FAQ(
        question: "同步包含哪些数据？",
        answer: "云同步包含：\n• 阅读进度和书签\n• 个人设置和主题偏好\n• 笔记和标注\n• 书籍元数据\n• 注意：不包含书籍文件本身",
        category: .sync,
        tags: ["数据", "同步", "内容"]
    ),
    
    // 设置选项
    FAQ(
        question: "如何设置夜间模式？",
        answer: "设置夜间模式：\n• 在阅读界面快速切换主题\n• 前往设置 → 主题设置 → 夜间模式\n• 可以设置自动切换时间\n• 支持跟随系统外观设置",
        category: .settings,
        tags: ["夜间", "模式", "自动"]
    ),
    
    // 故障排除
    FAQ(
        question: "应用闪退怎么办？",
        answer: "解决闪退问题：\n• 重启应用\n• 检查iOS系统版本\n• 释放设备存储空间\n• 重启设备\n• 如问题持续，请联系客服并提供详细信息",
        category: .troubleshooting,
        tags: ["闪退", "故障", "解决"]
    ),
    
    FAQ(
        question: "书籍无法打开？",
        answer: "书籍打开问题：\n• 检查文件格式是否支持\n• 确认文件没有损坏\n• 重新导入文件\n• 检查文件权限\n• 清除应用缓存后重试",
        category: .troubleshooting,
        tags: ["打开", "文件", "问题"]
    ),
    
    FAQ(
        question: "同步不工作？",
        answer: "同步问题排查：\n• 检查网络连接\n• 确认已登录iCloud\n• 检查iCloud存储空间\n• 在设置中重新启用同步\n• 尝试手动同步",
        category: .troubleshooting,
        tags: ["同步", "问题", "网络"]
    )
]

// MARK: - 辅助视图组件
struct QuickHelpCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FAQRow: View {
    let faq: FAQ
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onToggle()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(faq.question)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            Text(faq.category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                            
                            ForEach(faq.tags.prefix(2), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    Text(faq.answer)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        Button {
                            // TODO: 标记为有用
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "hand.thumbsup")
                                Text("有用")
                            }
                            .font(.caption)
                            .foregroundColor(.green)
                        }
                        
                        Button {
                            // TODO: 标记为无用
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "hand.thumbsdown")
                                Text("无用")
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        Button {
                            shareAnswer(faq)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .slide))
            }
        }
    }
    
    private func shareAnswer(_ faq: FAQ) {
        let shareText = "Q: \(faq.question)\n\nA: \(faq.answer)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview
struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HelpView()
        }
        .environmentObject(NavigationSystem.shared)
    }
}
