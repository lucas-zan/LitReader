// LitReaderSwift/Views/SearchView.swift
// 搜索界面

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchCategory: SearchCategory = .all
    @State private var showingSearchResults = false
    @State private var selectedBook: Book?
    
    enum SearchCategory: String, CaseIterable, Identifiable {
        case all = "全部"
        case title = "书名"
        case author = "作者"
        case content = "内容"
        case bookmark = "书签"
        case note = "笔记"
        
        var id: String { self.rawValue }
        
        var systemImageName: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .title: return "book"
            case .author: return "person"
            case .content: return "doc.text"
            case .bookmark: return "bookmark"
            case .note: return "note.text"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                searchBarView
                
                // 分类选项
                searchCategoriesView
                
                if showingSearchResults {
                    // 搜索结果
                    searchResultsView
                } else {
                    // 搜索建议
                    searchSuggestionsView
                }
                
                Spacer()
            }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedBook) { book in
                ReaderView(book: book)
            }
        }
    }
    
    // MARK: - 搜索栏
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索书籍、内容、书签...", text: $searchText)
                .font(.body)
                .onSubmit {
                    performSearch()
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
    }
    
    // MARK: - 分类选项
    private var searchCategoriesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SearchCategory.allCases) { category in
                    CategoryButton(
                        title: category.rawValue,
                        systemImageName: category.systemImageName,
                        isSelected: category == searchCategory
                    ) {
                        searchCategory = category
                        if !searchText.isEmpty {
                            performSearch()
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 搜索建议
    private var searchSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("搜索建议")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            ForEach(getSuggestions(), id: \.self) { suggestion in
                SuggestionRow(
                    icon: getSuggestionIcon(for: suggestion.type),
                    title: suggestion.title,
                    subtitle: suggestion.subtitle
                ) {
                    handleSuggestionTap(suggestion)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 搜索结果
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                let results = getSearchResults()
                
                Text("找到 \(results.count) 条结果")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top)
                
                ForEach(results, id: \.book.id) { result in
                    SearchResultRow(result: result) {
                        selectedBook = result.book
                    }
                }
                
                if results.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("未找到结果")
                            .font(.headline)
                        
                        Text("尝试使用不同的关键词或分类")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .padding(.bottom)
        }
    }
    
    // MARK: - 助手方法
    private func performSearch() {
        showingSearchResults = !searchText.isEmpty
    }
    
    private func getSearchResults() -> [SearchViewResult] {
        guard !searchText.isEmpty else { return [] }
        
        // 根据分类和关键词进行搜索
        var results: [SearchViewResult] = []
        
        // 获取符合条件的书籍
        var filteredBooks: [Book]
        
        switch searchCategory {
        case .all:
            filteredBooks = dataManager.searchBooks(query: searchText)
        case .title:
            filteredBooks = dataManager.library.books.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        case .author:
            filteredBooks = dataManager.library.books.filter { $0.author?.localizedCaseInsensitiveContains(searchText) == true }
        case .content:
            // 内容搜索需要额外实现
            filteredBooks = []
            // TODO: 实现内容搜索
        case .bookmark:
            // 书签搜索
            filteredBooks = []  // 初始化为空数组
            // 遍历所有书籍的书签
            for book in dataManager.library.books {
                let bookmarks = dataManager.getBookmarks(for: book.id)
                let matchedBookmarks = bookmarks.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.note.localizedCaseInsensitiveContains(searchText) }
                
                if !matchedBookmarks.isEmpty {
                    filteredBooks.append(book)
                }
            }
        case .note:
            // 笔记搜索
            filteredBooks = []
            // TODO: 实现笔记搜索
        }
        
        // 转换为搜索结果
        for book in filteredBooks {
            let result = SearchViewResult(
                book: book,
                matchType: searchCategory,
                matchText: searchText,
                matchDetails: "在\(searchCategory.rawValue)中找到匹配项"
            )
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - 搜索建议
    private func getSuggestions() -> [SearchSuggestion] {
        let recentBooks = dataManager.library.books.sorted(by: { ($0.lastReadAt ?? Date.distantPast) > ($1.lastReadAt ?? Date.distantPast) }).prefix(3)
        let popularSearches = [
            SearchSuggestion(type: .title, title: "按书名搜索", subtitle: "查找特定书籍"),
            SearchSuggestion(type: .author, title: "按作者搜索", subtitle: "查找作者的所有作品"),
            SearchSuggestion(type: .content, title: "全文搜索", subtitle: "在书籍内容中搜索"),
            SearchSuggestion(type: .bookmark, title: "按书签搜索", subtitle: "查找保存的书签")
        ]
        
        var suggestions: [SearchSuggestion] = []
        
        // 添加最近阅读的书籍
        for book in recentBooks {
            suggestions.append(
                SearchSuggestion(
                    type: .recent,
                    title: book.title,
                    subtitle: book.author ?? "未知作者",
                    relatedBook: book
                )
            )
        }
        
        // 添加热门搜索
        suggestions.append(contentsOf: popularSearches)
        
        return suggestions
    }
    
    private func getSuggestionIcon(for type: SearchSuggestion.SuggestionType) -> String {
        switch type {
        case .recent: return "clock"
        case .title: return "book"
        case .author: return "person"
        case .content: return "doc.text"
        case .bookmark: return "bookmark"
        }
    }
    
    private func handleSuggestionTap(_ suggestion: SearchSuggestion) {
        switch suggestion.type {
        case .recent:
            if let book = suggestion.relatedBook {
                selectedBook = book
            }
        case .title:
            searchCategory = .title
        case .author:
            searchCategory = .author
        case .content:
            searchCategory = .content
        case .bookmark:
            searchCategory = .bookmark
        }
    }
}

// MARK: - 助手视图
struct CategoryButton: View {
    let title: String
    let systemImageName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImageName)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

struct SuggestionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

struct SearchResultRow: View {
    let result: SearchViewResult
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 16) {
                // 书籍封面
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brown.gradient)
                    .frame(width: 60, height: 80)
                    .overlay(
                        Text(result.book.title.prefix(2))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.book.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let author = result.book.author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(result.matchDetails)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - 数据模型
struct SearchViewResult {
    let book: Book
    let matchType: SearchView.SearchCategory
    let matchText: String
    let matchDetails: String
}

struct SearchSuggestion: Hashable {
    enum SuggestionType {
        case recent, title, author, content, bookmark
    }
    
    let type: SuggestionType
    let title: String
    let subtitle: String
    let relatedBook: Book?
    
    init(type: SuggestionType, title: String, subtitle: String, relatedBook: Book? = nil) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.relatedBook = relatedBook
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subtitle)
    }
    
    static func == (lhs: SearchSuggestion, rhs: SearchSuggestion) -> Bool {
        return lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
    }
}

#Preview {
    SearchView()
        .environmentObject(DataManager.shared)
}