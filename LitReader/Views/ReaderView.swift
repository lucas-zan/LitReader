// LitReaderSwift/Views/ReaderView.swift
// 阅读界面

import SwiftUI

struct ReaderView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var content: String = ""
    @State private var currentPage = 0
    @State private var totalPages = 0
    @State private var showControls = false
    @State private var isLoading = true
    @State private var error: Error?
    @State private var readingSettings = AppSettings.default.defaultReadingSettings
    @State private var showingSettings = false
    @State private var bookmarkNote = ""
    @State private var showingBookmarkSheet = false
    @State private var showingTOC = false
    
    private let charactersPerPage = 800
    
    var pages: [String] {
        guard !content.isEmpty else { return [] }
        
        var pageArray: [String] = []
        let contentLength = content.count
        
        for i in stride(from: 0, to: contentLength, by: charactersPerPage) {
            let endIndex = min(i + charactersPerPage, contentLength)
            let startIdx = content.index(content.startIndex, offsetBy: i)
            let endIdx = content.index(content.startIndex, offsetBy: endIndex)
            pageArray.append(String(content[startIdx..<endIdx]))
        }
        
        return pageArray.isEmpty ? ["内容为空"] : pageArray
    }
    
    var currentPageContent: String {
        guard currentPage < pages.count else { return "" }
        return pages[currentPage]
    }
    
    var body: some View {
        ZStack {
            // 背景色
            readingSettings.backgroundUIColor
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView("加载中...")
                    .font(.headline)
            } else if let error = error {
                VStack {
                    Text("加载失败")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                    Button("返回") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                // 阅读内容
                ScrollView {
                    Text(currentPageContent)
                        .font(.custom(readingSettings.fontFamily, size: readingSettings.fontSize))
                        .foregroundColor(readingSettings.textUIColor)
                        .lineSpacing(readingSettings.fontSize * (readingSettings.lineHeight - 1))
                        .padding(.horizontal, readingSettings.pageMargin)
                        .padding(.top, showControls ? 80 : 20)
                        .padding(.bottom, showControls ? 100 : 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls.toggle()
                    }
                }
                
                // 顶部控制栏
                if showControls {
                    VStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text(book.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "textformat")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: { showingTOC = true }) {
                                Image(systemName: "list.bullet")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(.black.opacity(0.8))
                        
                        Spacer()
                    }
                    .transition(.move(edge: .top))
                }
                
                // 底部控制栏
                if showControls {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Button("上一页") {
                                previousPage()
                            }
                            .disabled(currentPage <= 0)
                            
                            Spacer()
                            
                            Text("\(currentPage + 1) / \(totalPages)")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: addBookmark) {
                                Image(systemName: "bookmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: { navigateToBookmarks() }) {
                                Image(systemName: "bookmark.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Button("下一页") {
                                nextPage()
                            }
                            .disabled(currentPage >= totalPages - 1)
                        }
                        .padding()
                        .background(.black.opacity(0.8))
                        .cornerRadius(25)
                        .padding()
                    }
                    .transition(.move(edge: .bottom))
                }
                
                // 进度指示器
                VStack {
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.brown)
                        .frame(height: 2)
                        .frame(width: UIScreen.main.bounds.width * CGFloat(currentPage + 1) / CGFloat(max(totalPages, 1)))
                        .animation(.easeInOut, value: currentPage)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadBookContent()
            loadReadingProgress()
        }
        .onDisappear {
            saveReadingProgress()
        }
        .sheet(isPresented: $showingSettings) {
            ReadingSettingsView(settings: $readingSettings)
        }
        .sheet(isPresented: $showingBookmarkSheet) {
            BookmarkAddView(book: book, position: Double(currentPage), note: $bookmarkNote, onAdd: addBookmarkWithNote)
        }
        .sheet(isPresented: $showingTOC) {
            TOCView(book: book, content: content, currentPage: $currentPage, totalPages: totalPages) {
                showingTOC = false
            }
        }
    }
    
    // MARK: - 页面控制
    private func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
            saveReadingProgress()
        }
    }
    
    private func nextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
            saveReadingProgress()
        }
    }
    
    // MARK: - 内容加载
    private func loadBookContent() {
        Task {
            do {
                let bookContent = try dataManager.getBookContent(for: book)
                
                await MainActor.run {
                    content = bookContent
                    totalPages = pages.count
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - 阅读进度
    private func loadReadingProgress() {
        if let progress = dataManager.getReadingProgress(for: book.id) {
            currentPage = progress.currentPage
            totalPages = max(progress.totalPages, 1)
        }
    }
    
    private func saveReadingProgress() {
        let progress = totalPages > 0 ? Double(currentPage) / Double(totalPages) : 0.0
        
        // 保存进度
        var readingProgress = dataManager.getReadingProgress(for: book.id) ?? ReadingProgress(bookId: book.id, currentPage: currentPage, totalPages: totalPages)
        readingProgress.currentPage = currentPage
        readingProgress.totalPages = totalPages
        readingProgress.progressPercentage = progress
        readingProgress.lastReadAt = Date()
        
        dataManager.saveReadingProgress(readingProgress)
    }
    
    // MARK: - 书签功能
    private func addBookmark() {
        showingBookmarkSheet = true
    }
    
    private func addBookmarkWithNote() {
        let bookmark = Bookmark(
            bookId: book.id,
            position: currentPage,
            title: "第 \(currentPage + 1) 页",
            note: bookmarkNote
        )
        dataManager.addBookmark(bookmark)
        bookmarkNote = ""
        showingBookmarkSheet = false
    }
    
    private func navigateToBookmarks() {
        // TODO: 实现导航到书签页面
        print("导航到书签页面")
    }
}

// MARK: - 书签添加视图
struct BookmarkAddView: View {
    let book: Book
    let position: Double
    @Binding var note: String
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("书签信息") {
                    HStack {
                        Text("书籍")
                        Spacer()
                        Text(book.title)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("位置")
                        Spacer()
                        Text("第 \(Int(position) + 1) 页")
                            .foregroundColor(.secondary)
                    }
                    
                    TextField("书签备注（可选）", text: $note)
                }
            }
            .navigationTitle("添加书签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onAdd()
                    }
                }
            }
        }
    }
}

#Preview {
    ReaderView(book: Book(title: "示例书籍", filePath: "", format: .txt))
        .environmentObject(DataManager.shared)
}