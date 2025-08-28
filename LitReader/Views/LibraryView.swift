// LitReaderSwift/Views/LibraryView.swift
// 书架界面

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var fileImporter = FileImporter.shared
    
    @State private var showingFilePicker = false
    @State private var showingSearchView = false
    @State private var searchText = ""
    @State private var selectedBook: Book?
    @State private var showingReader = false
    
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return dataManager.library.books
        } else {
            return dataManager.searchBooks(query: searchText)
        }
    }
    
    var body: some View {
        VStack {
            if dataManager.isLoading {
                LoadingView()
            } else if dataManager.library.books.isEmpty {
                EmptyLibraryView()
            } else {
                BookGridView(books: filteredBooks, onBookTap: openBook)
            }
        }
        .navigationTitle("LitReader")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showingSearchView = true }) {
                    Image(systemName: "magnifyingglass")
                }
                
                Button(action: { showingFilePicker = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingSearchView) {
            SearchView()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: fileImporter.getSupportedFileTypes(),
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result)
        }
        .sheet(item: $selectedBook) { book in
            ReaderView(book: book)
        }
        .alert("错误", isPresented: .constant(dataManager.error != nil)) {
            Button("确定") {
                dataManager.error = nil
            }
        } message: {
            Text(dataManager.error?.localizedDescription ?? "")
        }
        .overlay {
            if fileImporter.isImporting {
                ImportProgressView(progress: fileImporter.importProgress)
            }
        }
    }
    
    private func openBook(_ book: Book) {
        selectedBook = book
        
        // 更新打开次数
        var updatedBook = book
        updatedBook.openCount += 1
        updatedBook.lastReadAt = Date()
        dataManager.updateBook(updatedBook)
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                await fileImporter.importFiles(from: urls)
            }
        case .failure(let error):
            dataManager.error = error
        }
    }
}

// MARK: - 空状态视图
struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("暂无书籍")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("点击右上角的 + 按钮添加你的第一本书")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - 加载视图
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("加载中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 导入进度视图
struct ImportProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("导入中... \(Int(progress * 100))%")
                .font(.headline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding()
    }
}

// MARK: - 书籍网格视图
struct BookGridView: View {
    let books: [Book]
    let onBookTap: (Book) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(books) { book in
                    BookCardView(book: book, onTap: { onBookTap(book) })
                }
            }
            .padding()
        }
    }
}

// MARK: - 书籍卡片视图
struct BookCardView: View {
    let book: Book
    let onTap: () -> Void
    @EnvironmentObject var dataManager: DataManager
    
    @State private var showingDeleteAlert = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                // 书籍封面
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.brown.gradient)
                    .frame(height: 160)
                    .overlay {
                        VStack {
                            Text(book.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                            
                            Spacer()
                            
                            if book.progress > 0 {
                                ProgressView(value: book.progress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            }
                        }
                        .padding(12)
                    }
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isPressed)
                
                // 移除了右上角的删除按钮
            }
            
            // 书籍信息
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let author = book.author {
                    Text(author)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text("进度: \(Int(book.progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        }
        .contextMenu {
            Button("删除", role: .destructive) {
                showingDeleteAlert = true
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                dataManager.removeBook(withId: book.id)
            }
        } message: {
            Text("确定要删除《\(book.title)》吗？")
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(DataManager.shared)
}