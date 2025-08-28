import SwiftUI

struct BookmarksView: View {
    let bookId: String
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var bookmarks: [Bookmark] = []
    @State private var selectedBookmark: Bookmark?
    @State private var showingAlert = false
    @State private var bookmarkToDelete: Bookmark?
    
    var body: some View {
        List {
            if bookmarks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                    
                    Text("暂无书签")
                        .font(.headline)
                    
                    Text("阅读时，点击底部工具栏的书签按钮添加书签")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
            } else {
                ForEach(bookmarks) { bookmark in
                    BookmarkRow(bookmark: bookmark)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBookmark = bookmark
                            dismiss()
                        }
                        .contextMenu {
                            Button(action: {
                                bookmarkToDelete = bookmark
                                showingAlert = true
                            }) {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
                .onDelete(perform: deleteBookmarks)
            }
        }
        .navigationTitle("书签")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadBookmarks()
        }
        .alert("确认删除", isPresented: $showingAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let bookmark = bookmarkToDelete {
                    deleteBookmark(bookmark)
                }
            }
        } message: {
            Text("确定要删除这个书签吗？")
        }
    }
    
    private func loadBookmarks() {
        bookmarks = dataManager.getBookmarks(for: bookId).sorted { $0.createdAt > $1.createdAt }
    }
    
    private func deleteBookmarks(at offsets: IndexSet) {
        for index in offsets {
            let bookmark = bookmarks[index]
            dataManager.removeBookmark(withId: bookmark.id)
        }
        loadBookmarks()
    }
    
    private func deleteBookmark(_ bookmark: Bookmark) {
        dataManager.removeBookmark(withId: bookmark.id)
        loadBookmarks()
    }
}

struct BookmarkRow: View {
    let bookmark: Bookmark
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private var positionText: String {
        let percent = Int(bookmark.position * 100)
        return "进度: \(percent)%"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.blue)
                
                Text(dateFormatter.string(from: bookmark.createdAt))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(positionText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            if !bookmark.note.isEmpty {
                Text(bookmark.note)
                    .font(.body)
                    .lineLimit(3)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationView {
        BookmarksView(bookId: "example-id")
            .environmentObject(DataManager.shared)
    }
}