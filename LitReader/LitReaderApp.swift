import SwiftUI

@main
struct LitReaderApp: App {
    // 初始化数据管理器
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var navigationSystem = NavigationSystem.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(navigationSystem)
                .environmentObject(themeManager)
                .onAppear {
                    // 应用启动时的初始化
                    setupApplication()
                }
        }
    }
    
    private func setupApplication() {
        // 加载用户数据
        dataManager.loadLibrary()
        
        // 扫描Books目录中的文件
        dataManager.scanBooksDirectory()
        
        // 加载主题设置
        themeManager.loadSavedTheme()
        
        // 初始化导航系统
        navigationSystem.configure(.default)
    }
}