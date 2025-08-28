import Foundation
import SwiftUI
import Combine

// MARK: - Bookshelf Layout
struct BookshelfLayout: Codable {
    var shelves: [Shelf]
    var currentShelf: Int
    var displayMode: DisplayMode
    
    enum DisplayMode: String, Codable, CaseIterable {
        case grid = "grid"
        case list = "list"
        case shelf3D = "3d"
        
        var displayName: String {
            switch self {
            case .grid: return "网格视图"
            case .list: return "列表视图"
            case .shelf3D: return "3D书架"
            }
        }
    }
}

// MARK: - Shelf
struct Shelf: Codable, Identifiable {
    let id: String
    var name: String
    var books: [String] // Book IDs
    let capacity: Int
    var theme: ShelfTheme
    
    enum ShelfTheme: String, Codable, CaseIterable {
        case wood = "wood"
        case metal = "metal"
        case glass = "glass"
        
        var color: Color {
            switch self {
            case .wood: return Color.brown
            case .metal: return Color.gray
            case .glass: return Color.blue.opacity(0.3)
            }
        }
    }
}

// MARK: - Bookshelf Manager
@MainActor
class BookshelfManager: ObservableObject {
    static let shared = BookshelfManager()
    
    @Published var bookshelfLayout = BookshelfLayout(
        shelves: [],
        currentShelf: 0,
        displayMode: .shelf3D
    )
    
    private init() {
        setupDefaultShelf()
        loadLayout()
    }
    
    private func setupDefaultShelf() {
        let defaultShelf = Shelf(
            id: "default",
            name: "我的书架",
            books: [],
            capacity: 50,
            theme: .wood
        )
        
        bookshelfLayout = BookshelfLayout(
            shelves: [defaultShelf],
            currentShelf: 0,
            displayMode: .shelf3D
        )
    }
    
    // MARK: - Book Arrangement
    func arrangeBooks(_ books: [Book]) -> [Book] {
        return books.sorted { a, b in
            // 按最近阅读时间排序
            if let aLastRead = a.lastReadAt, let bLastRead = b.lastReadAt {
                return aLastRead > bLastRead
            }
            
            // 按添加时间排序
            return a.addedAt > b.addedAt
        }
    }
    
    func distributeToShelves(_ books: [Book]) {
        let arrangedBooks = arrangeBooks(books)
        var shelves: [Shelf] = []
        var currentShelf = createNewShelf(index: 0)
        
        for book in arrangedBooks {
            if currentShelf.books.count >= currentShelf.capacity {
                shelves.append(currentShelf)
                currentShelf = createNewShelf(index: shelves.count)
            }
            
            currentShelf.books.append(book.id)
        }
        
        if !currentShelf.books.isEmpty {
            shelves.append(currentShelf)
        }
        
        if shelves.isEmpty {
            shelves.append(createNewShelf(index: 0))
        }
        
        bookshelfLayout.shelves = shelves
        saveLayout()
    }
    
    private func createNewShelf(index: Int) -> Shelf {
        return Shelf(
            id: "shelf_\(index)",
            name: "书架 \(index + 1)",
            books: [],
            capacity: 20,
            theme: .wood
        )
    }
    
    // MARK: - Layout Management
    func updateDisplayMode(_ mode: BookshelfLayout.DisplayMode) {
        withAnimation(.easeInOut(duration: 0.5)) {
            bookshelfLayout.displayMode = mode
        }
        saveLayout()
    }
    
    func switchToShelf(_ index: Int) {
        guard index >= 0 && index < bookshelfLayout.shelves.count else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            bookshelfLayout.currentShelf = index
        }
        saveLayout()
    }
    
    // MARK: - Persistence
    func saveLayout() {
        do {
            let data = try JSONEncoder().encode(bookshelfLayout)
            UserDefaults.standard.set(data, forKey: "bookshelf_layout")
        } catch {
            print("保存书架布局失败: \(error)")
        }
    }
    
    func loadLayout() {
        guard let data = UserDefaults.standard.data(forKey: "bookshelf_layout") else {
            return
        }
        
        do {
            bookshelfLayout = try JSONDecoder().decode(BookshelfLayout.self, from: data)
        } catch {
            print("加载书架布局失败: \(error)")
        }
    }
}