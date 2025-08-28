import SwiftUI

struct BookDetailsView: View {
    let book: Book
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var navigationSystem: NavigationSystem
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var readingEngine: ReadingEngine
    
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var isEditing = false
    @State private var editedBook: Book
    
    init(book: Book) {
        self.book = book
        self._editedBook = State(initialValue: book)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 书籍封面和基本信息
                bookHeaderSection
                
                // 阅读进度
                readingProgressSection
                
                // 书籍统计
                statisticsSection
                
                // 书签数量
                bookmarksSection
                
                // 元数据信息
                metadataSection
                
                // 操作按钮
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("编辑信息") {
                        showingEditSheet = true
                    }
                    
                    Button("导出书签") {
                        exportBookmarks()
                    }
                    
                    Button("删除书籍", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            editBookSheet
        }
        .alert("删除书籍", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteBook()
            }
        } message: {
            Text("确定要删除《\(book.title)》吗？此操作无法撤销。")
        }
    }
    
    // MARK: - 书籍头部信息
    private var bookHeaderSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // 封面图片
            AsyncImage(url: book.coverImagePath.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 100, height: 140)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textUIColor)
                
                Text(book.author ?? "未知作者")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "doc.text")
                    Text(book.format.rawValue.uppercased())
                    
                    Spacer()
                    
                    Image(systemName: "externaldrive")
                    Text(formatFileSize(book.fileSize))
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if book.isFavorite {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("已收藏")
                    }
                    .font(.caption)
                }
                
                if !book.tags.isEmpty {
                    LazyVStack(alignment: .leading) {
                        ForEach(book.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - 阅读进度部分
    private var readingProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("阅读进度")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textUIColor)
            
            VStack(spacing: 8) {
                HStack {
                    Text("进度")
                    Spacer()
                    Text("\(Int(book.progress * 100))%")
                        .fontWeight(.medium)
                }
                
                ProgressView(value: book.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                HStack {
                    Text("第 \(book.currentPage) 页")
                    Spacer()
                    Text("共 \(book.totalPages) 页")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 统计信息部分
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("阅读统计")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textUIColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "阅读时长",
                    value: formatReadingTime(book.readingTime),
                    icon: "clock"
                )
                
                StatCard(
                    title: "打开次数",
                    value: "\(book.openCount)",
                    icon: "eye"
                )
                
                StatCard(
                    title: "添加时间",
                    value: formatDate(book.addedAt),
                    icon: "calendar"
                )
                
                if let lastRead = book.lastReadAt {
                    StatCard(
                        title: "最后阅读",
                        value: formatDate(lastRead),
                        icon: "book.closed"
                    )
                }
            }
        }
    }
    
    // MARK: - 书签部分
    private var bookmarksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("书签")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textUIColor)
                
                Spacer()
                
                Button("查看全部") {
                    Task {
                        try? await navigationSystem.navigate(to: .bookmarks(bookId: book.id))
                    }
                }
                .font(.caption)
            }
            
            let bookmarks = bookmarkManager.getBookmarks(for: book.id)
            
            if bookmarks.isEmpty {
                Text("暂无书签")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(bookmarks.prefix(3)) { bookmark in
                        BookmarkRow(bookmark: bookmark)
                    }
                    
                    if bookmarks.count > 3 {
                        Text("还有 \(bookmarks.count - 3) 个书签...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - 元数据部分
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细信息")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textUIColor)
            
            VStack(spacing: 8) {
                MetadataRow(key: "文件路径", value: book.filePath)
                MetadataRow(key: "文件大小", value: formatFileSize(book.fileSize))
                MetadataRow(key: "文件格式", value: book.format.rawValue.uppercased())
                MetadataRow(key: "添加时间", value: formatFullDate(book.addedAt))
                
                if let lastSync = book.lastSyncAt {
                    MetadataRow(key: "最后同步", value: formatFullDate(lastSync))
                }
                
                if !book.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("笔记:")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(book.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 操作按钮部分
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    try? await navigationSystem.navigate(to: .reader(book: book))
                }
            } label: {
                HStack {
                    Image(systemName: "book.open")
                    Text(book.progress > 0 ? "继续阅读" : "开始阅读")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                Button {
                    toggleFavorite()
                } label: {
                    HStack {
                        Image(systemName: book.isFavorite ? "heart.fill" : "heart")
                        Text(book.isFavorite ? "已收藏" : "收藏")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(book.isFavorite ? .red : .primary)
                    .cornerRadius(8)
                }
                
                Button {
                    shareBook()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("分享")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - 编辑书籍表单
    private var editBookSheet: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("书名", text: $editedBook.title)
                    TextField("作者", text: Binding(
                        get: { editedBook.author ?? "" },
                        set: { editedBook.author = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section("标签") {
                    // TODO: 实现标签编辑
                    Text("标签编辑功能")
                        .foregroundColor(.secondary)
                }
                
                Section("笔记") {
                    TextEditor(text: $editedBook.notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("编辑书籍")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        editedBook = book
                        showingEditSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveEditedBook()
                    }
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    private func deleteBook() {
        Task {
            dataManager.removeBook(withId: book.id)
            try? await navigationSystem.goBack()
        }
    }
    
    private func toggleFavorite() {
        Task {
            var updatedBook = book
            updatedBook.isFavorite.toggle()
            dataManager.updateBook(updatedBook)
        }
    }
    
    private func shareBook() {
        // TODO: 实现分享功能
    }
    
    private func exportBookmarks() {
        // TODO: 实现书签导出
    }
    
    private func saveEditedBook() {
        Task {
            dataManager.updateBook(editedBook)
            showingEditSheet = false
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatReadingTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 辅助视图
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct MetadataRow: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}



// MARK: - Preview
struct BookDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BookDetailsView(book: Book.example)
        }
        .environmentObject(DataManager.shared)
        .environmentObject(NavigationSystem.shared)
        .environmentObject(ThemeManager.shared)
        .environmentObject(BookmarkManager.shared)
        .environmentObject(ReadingEngine.shared)
    }
}

#Preview {
    NavigationView {
        BookDetailsView(book: Book.example)
    }
    .environmentObject(DataManager.shared)
    .environmentObject(NavigationSystem.shared)
    .environmentObject(ThemeManager.shared)
    .environmentObject(BookmarkManager.shared)
    .environmentObject(ReadingEngine.shared)
}