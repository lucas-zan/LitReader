// LitReaderSwift/Views/AdvancedReaderView.swift
// 高级阅读界面

import SwiftUI

// MARK: - Reading Settings
struct ReadingSettings {
    var fontSize: Double = 16
    var lineHeight: Double = 1.5
    var pageMargin: Double = 20
    var backgroundColor: String = "#FFFFFF"
    var textColor: String = "#333333"
    var theme: ReadingTheme.Theme = .light
}

extension ReadingTheme {
    enum Theme {
        case light, dark, sepia
    }
}

struct AdvancedReaderView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var readingEngine = ReadingEngine.shared
    @StateObject private var searchService = SearchService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var showControls = false
    @State private var showTOC = false
    @State private var showSearch = false
    @State private var showBookmarks = false
    @State private var showSettings = false
    @State private var searchQuery = ""
    @State private var readingSettings = ReadingSettings()
    @State private var isLoading = true
    @State private var currentPageIndex = 0
    @State private var pages: [Page] = []
    @State private var currentChapter: Chapter?
    @State private var tableOfContents: TableOfContents?
    
    var body: some View {
        ZStack {
            // 背景
            Color(red: 1.0, green: 1.0, blue: 1.0)
                .ignoresSafeArea()
            
            if isLoading {
                LoadingView()
            } else {
                // 主要阅读内容
                ReadingContentView()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showControls.toggle()
                        }
                    }
                
                // 控制界面
                if showControls {
                    ControlsOverlayView()
                }
                
                // 进度指示器
                ProgressIndicatorView()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadBook()
        }
        .sheet(isPresented: $showTOC) {
            TableOfContentsView()
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView(bookId: book.id)
        }
        .sheet(isPresented: $showSettings) {
            AdvancedReadingSettingsView(readingSettings: $readingSettings)
        }
    }
    
    // MARK: - Helper Methods
    private func loadBook() {
        // 模拟书籍加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            // 这里可以添加实际的书籍加载逻辑
        }
    }
    
    // MARK: - 阅读内容视图
    @ViewBuilder
    private func ReadingContentView() -> some View {
        if !pages.isEmpty && currentPageIndex < pages.count {
            let currentPage = pages[currentPageIndex]
            
            ScrollView {
                Text(currentPage.content)
                    .font(.system(size: readingSettings.fontSize))
                    .foregroundColor(.black)
                    .lineSpacing(readingSettings.fontSize * (readingSettings.lineHeight - 1))
                    .padding(.horizontal, readingSettings.pageMargin)
                    .padding(.top, showControls ? 100 : 30)
                    .padding(.bottom, showControls ? 120 : 30)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 50 {
                            // 向右滑动 - 上一页
                            previousPage()
                        } else if value.translation.width < -50 {
                            // 向左滑动 - 下一页
                            nextPage()
                        }
                    }
            )
        } else {
            Text("加载内容中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private func nextPage() {
        if currentPageIndex < pages.count - 1 {
            currentPageIndex += 1
        }
    }
    
    private func previousPage() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
        }
    }
    
    // MARK: - 控制界面
    @ViewBuilder
    private func ControlsOverlayView() -> some View {
        VStack {
            // 顶部控制栏
            TopControlBar()
            
            Spacer()
            
            // 底部控制栏
            BottomControlBar()
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func TopControlBar() -> some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
            if let chapter = currentChapter {
                    Text(chapter.title)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { showSearch = true }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "textformat")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(.black.opacity(0.8))
    }
    
    @ViewBuilder
    private func BottomControlBar() -> some View {
        VStack(spacing: 12) {
            // 页面指示器
            HStack {
                Spacer()
                Text("\(currentPageIndex + 1) / \(pages.count)")
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
            }
            
            // 控制按钮
            HStack(spacing: 20) {
                Button("上一页") {
                    previousPage()
                }
                .disabled(currentPageIndex <= 0)
                
                Button(action: { showTOC = true }) {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                }
                
                Button(action: { 
                    // 添加书签逻辑
                }) {
                    Image(systemName: "bookmark")
                        .font(.title2)
                }
                
                Button(action: { showBookmarks = true }) {
                    Image(systemName: "bookmark.fill")
                        .font(.title2)
                }
                
                Button("下一页") {
                    nextPage()
                }
                .disabled(currentPageIndex >= pages.count - 1)
            }
            .foregroundColor(.white)
        }
        .padding()
        .background(.black.opacity(0.8))
        .cornerRadius(25)
        .padding()
    }
    
    // MARK: - 进度指示器
    @ViewBuilder
    private func ProgressIndicatorView() -> some View {
        VStack {
            Spacer()
            
            Rectangle()
                .fill(Color.brown)
                .frame(height: 3)
                .frame(width: UIScreen.main.bounds.width * CGFloat(pages.isEmpty ? 0 : Double(currentPageIndex) / Double(pages.count)))
                .animation(.easeInOut, value: currentPageIndex)
        }
    }
}

// MARK: - 目录视图
struct TableOfContentsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var chapters: [Chapter] = []
    
    var body: some View {
        NavigationView {
            List {
                if !chapters.isEmpty {
                    ForEach(chapters) { chapter in
                        ChapterRowView(chapter: chapter)
                            .onTapGesture {
                                // 跳转到章节逻辑
                                dismiss()
                            }
                    }
                } else {
                    Text("正在生成目录...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("目录")
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

struct ChapterRowView: View {
    let chapter: Chapter
    @State private var isCurrentChapter = false
    
    var body: some View {
        HStack {
            // 层级缩进
            if chapter.level > 1 {
                ForEach(0..<chapter.level-1, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 20)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title)
                    .font(.body)
                    .foregroundColor(isCurrentChapter ? .blue : .primary)
                
                if let pageNumber = chapter.pageNumber {
                    Text("第 \(pageNumber) 页")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isCurrentChapter {
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// SearchView 已在独立文件中定义

struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("搜索内容...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button("搜索") {
                onSearchButtonClicked()
            }
        }
        .padding()
    }
}

// SearchResultRow 已在 SearchView.swift 中定义

// BookmarksView 已在独立文件中定义

struct BookmarkRowView: View {
    let bookmark: Bookmark
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bookmark.title.isEmpty ? "未命名书签" : bookmark.title)
                .font(.body)
            
            if !bookmark.note.isEmpty {
                Text(bookmark.note)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("创建时间: \(bookmark.createdAt.formatted())")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 高级阅读设置
struct AdvancedReadingSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var readingSettings: ReadingSettings
    
    var body: some View {
        NavigationView {
            Form {
                Section("字体设置") {
                    HStack {
                        Text("字体大小")
                        Spacer()
                        Slider(value: $readingSettings.fontSize, in: 12...28, step: 1)
                        Text("\(Int(readingSettings.fontSize))")
                            .frame(width: 30)
                    }
                    
                    HStack {
                        Text("行间距")
                        Spacer()
                        Slider(value: $readingSettings.lineHeight, in: 1.0...2.5, step: 0.1)
                        Text(String(format: "%.1f", readingSettings.lineHeight))
                            .frame(width: 30)
                    }
                    
                    HStack {
                        Text("页边距")
                        Spacer()
                        Slider(value: $readingSettings.pageMargin, in: 10...50, step: 5)
                        Text("\(Int(readingSettings.pageMargin))")
                            .frame(width: 30)
                    }
                }
                
                Section("主题设置") {
                    Button("浅色主题") { setLightTheme() }
                    Button("深色主题") { setDarkTheme() }
                    Button("护眼主题") { setSepiaTheme() }
                }
                
                Section("阅读体验") {
                    Text("更多设置开发中...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("阅读设置")
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
    
    private func setLightTheme() {
        readingSettings.backgroundColor = "#FFFFFF"
        readingSettings.textColor = "#333333"
        readingSettings.theme = .light
    }
    
    private func setDarkTheme() {
        readingSettings.backgroundColor = "#1C1C1E"
        readingSettings.textColor = "#FFFFFF"
        readingSettings.theme = .dark
    }
    
    private func setSepiaTheme() {
        readingSettings.backgroundColor = "#F7F3E9"
        readingSettings.textColor = "#5D4E37"
        readingSettings.theme = .sepia
    }
}

#Preview {
    AdvancedReaderView(book: Book(title: "示例书籍", filePath: "", format: .txt))
}