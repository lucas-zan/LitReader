import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var navigationSystem: NavigationSystem
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            switch navigationSystem.state.currentRoute {
            case .library:
                LibraryView()
            case .reader(let book):
                ReaderView(book: book)
            case .settings:
                SettingsView()
            case .bookDetails(let book):
                BookDetailsView(book: book)
            case .bookmarks(let bookId):
                BookmarksView(bookId: bookId)
            case .search:
                SearchView()
            case .profile:
                ProfileView()
            case .about:
                AboutView()
            case .help:
                HelpView()
            case .themes:
                ThemeSelectionView()
            case .importBooks:
                ImportBooksView()
            case .statistics:
                StatisticsView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DataManager.shared)
            .environmentObject(NavigationSystem.shared)
            .environmentObject(ThemeManager.shared)
    }
}