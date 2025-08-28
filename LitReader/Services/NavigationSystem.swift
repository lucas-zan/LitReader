import Foundation
import SwiftUI
import Combine

// MARK: - App Route
enum AppRoute: Hashable {
    case library
    case reader(book: Book)
    case settings
    case bookDetails(book: Book)
    case bookmarks(bookId: String)
    case search
    case profile
    case about
    case help
    case themes
    case importBooks
    case statistics
    
    var title: String {
        switch self {
        case .library: return "书库"
        case .reader: return "阅读"
        case .settings: return "设置"
        case .bookDetails: return "书籍详情"
        case .bookmarks: return "书签"
        case .search: return "搜索"
        case .profile: return "个人资料"
        case .about: return "关于"
        case .help: return "帮助"
        case .themes: return "主题"
        case .importBooks: return "导入书籍"
        case .statistics: return "统计"
        }
    }
}

// MARK: - Navigation State
struct NavigationState {
    var currentRoute: AppRoute = .library
    var navigationStack: [AppRoute] = []
    var canGoBack: Bool = false
    var canGoForward: Bool = false
}

// MARK: - Navigation Configuration
struct NavigationConfig {
    let enableHistory: Bool
    let maxHistorySize: Int
    let animationDuration: TimeInterval
    
    static let `default` = NavigationConfig(
        enableHistory: true,
        maxHistorySize: 100,
        animationDuration: 0.3
    )
}

// MARK: - Navigation System
@MainActor
class NavigationSystem: ObservableObject {
    static let shared = NavigationSystem()
    
    @Published var state = NavigationState()
    @Published var config = NavigationConfig.default
    @Published var isNavigating = false
    
    private var forwardStack: [AppRoute] = []
    
    private init() {
        setupInitialState()
    }
    
    private func setupInitialState() {
        state.currentRoute = .library
        state.navigationStack = [.library]
    }
    
    func configure(_ config: NavigationConfig) {
        self.config = config
    }
    
    // MARK: - Navigation
    func navigate(to route: AppRoute) async throws {
        guard !isNavigating else { return }
        
        isNavigating = true
        defer { isNavigating = false }
        
        // 清空前进栈
        forwardStack.removeAll()
        
        // 添加到导航栈
        state.navigationStack.append(route)
        state.currentRoute = route
        
        updateNavigationState()
        
        // 动画延迟
        try await Task.sleep(nanoseconds: UInt64(config.animationDuration * 1_000_000_000))
    }
    
    func goBack() async throws {
        guard canGoBack() else { return }
        
        let currentRoute = state.navigationStack.removeLast()
        forwardStack.append(currentRoute)
        
        state.currentRoute = state.navigationStack.last ?? .library
        updateNavigationState()
    }
    
    func goForward() async throws {
        guard canGoForward() else { return }
        
        let route = forwardStack.removeLast()
        state.navigationStack.append(route)
        state.currentRoute = route
        updateNavigationState()
    }
    
    private func canGoBack() -> Bool {
        return state.navigationStack.count > 1
    }
    
    private func canGoForward() -> Bool {
        return !forwardStack.isEmpty
    }
    
    private func updateNavigationState() {
        state.canGoBack = canGoBack()
        state.canGoForward = canGoForward()
    }
    
    // MARK: - Quick Navigation
    func navigateToReader(book: Book) async throws {
        try await navigate(to: .reader(book: book))
    }
    
    func returnToLibrary() async throws {
        try await navigate(to: .library)
        state.navigationStack = [.library]
        forwardStack.removeAll()
        updateNavigationState()
    }
}