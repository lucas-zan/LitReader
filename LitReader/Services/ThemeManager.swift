import Foundation
import SwiftUI
import Combine

// MARK: - Reading Theme
struct ReadingTheme: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var backgroundColor: CodableColor
    var textColor: CodableColor
    var accentColor: CodableColor
    var fontSize: Double
    var fontFamily: String
    var lineHeight: Double
    var pageMargin: Double
    var isDark: Bool
    var isCustom: Bool = false
    
    // SwiftUI Color properties
    var backgroundUIColor: Color {
        return backgroundColor.color
    }
    
    var textUIColor: Color {
        return textColor.color
    }
    
    var accentUIColor: Color {
        return accentColor.color
    }
    
    var colorScheme: ColorScheme {
        return isDark ? .dark : .light
    }
    
    init(id: UUID = UUID(), name: String, backgroundColor: Color, textColor: Color, accentColor: Color, 
         fontSize: Double = 16, fontFamily: String = "System", lineHeight: Double = 1.5, 
         pageMargin: Double = 20, isDark: Bool = false, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.backgroundColor = CodableColor(backgroundColor)
        self.textColor = CodableColor(textColor)
        self.accentColor = CodableColor(accentColor)
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.lineHeight = lineHeight
        self.pageMargin = pageMargin
        self.isDark = isDark
        self.isCustom = isCustom
    }
    
    static func == (lhs: ReadingTheme, rhs: ReadingTheme) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Codable Color
struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    var color: Color {
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
    
    init(_ color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
}

// MARK: - Font Settings
struct FontSettings: Codable {
    let family: String
    let size: Double
    let weight: String
    
    static let `default` = FontSettings(family: "System", size: 16, weight: "regular")
    
    var font: Font {
        let fontSize = CGFloat(size)
        switch family.lowercased() {
        case "system":
            return .system(size: fontSize)
        case "serif":
            return .system(size: fontSize, design: .serif)
        case "monospace":
            return .system(size: fontSize, design: .monospaced)
        default:
            return .custom(family, size: fontSize)
        }
    }
}

// MARK: - Theme Manager
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: ReadingTheme
    @Published var availableThemes: [ReadingTheme] = []
    @Published var customThemes: [ReadingTheme] = []
    @Published var fontSettings = FontSettings.default
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        // 初始化默认主题
        self.currentTheme = Self.lightTheme
        setupDefaultThemes()
        loadSavedTheme()
        loadCustomThemes()
    }
    
    // MARK: - Default Themes
    private func setupDefaultThemes() {
        availableThemes = [
            Self.lightTheme,
            Self.darkTheme,
            Self.sepiaTheme,
            Self.nightTheme,
            Self.paperTheme,
            Self.greenTheme
        ]
    }
    
    static let lightTheme = ReadingTheme(
        name: "light",
        backgroundColor: .white,
        textColor: .black,
        accentColor: .blue,
        fontSize: 16,
        fontFamily: "System",
        lineHeight: 1.5,
        pageMargin: 20,
        isDark: false
    )
    
    static let darkTheme = ReadingTheme(
        name: "dark", 
        backgroundColor: Color(.systemGray6),
        textColor: .white,
        accentColor: .orange,
        fontSize: 16,
        fontFamily: "System",
        lineHeight: 1.5,
        pageMargin: 20,
        isDark: true
    )
    
    static let sepiaTheme = ReadingTheme(
        name: "sepia",
        backgroundColor: Color(red: 0.97, green: 0.94, blue: 0.86),
        textColor: Color(red: 0.2, green: 0.15, blue: 0.1),
        accentColor: Color(red: 0.6, green: 0.4, blue: 0.2),
        fontSize: 16,
        fontFamily: "System",
        lineHeight: 1.5,
        pageMargin: 20,
        isDark: false
    )
    
    static let nightTheme = ReadingTheme(
        name: "night",
        backgroundColor: Color(red: 0.05, green: 0.05, blue: 0.05),
        textColor: Color(red: 0.8, green: 0.8, blue: 0.8),
        accentColor: Color(red: 0.3, green: 0.6, blue: 0.9),
        fontSize: 16,
        fontFamily: "System",
        lineHeight: 1.5,
        pageMargin: 20,
        isDark: true
    )
    
    static let paperTheme = ReadingTheme(
        name: "paper",
        backgroundColor: Color(red: 0.99, green: 0.98, blue: 0.95),
        textColor: Color(red: 0.1, green: 0.1, blue: 0.1),
        accentColor: Color(red: 0.4, green: 0.5, blue: 0.7),
        fontSize: 16,
        fontFamily: "Serif",
        lineHeight: 1.6,
        pageMargin: 25,
        isDark: false
    )
    
    static let greenTheme = ReadingTheme(
        name: "green",
        backgroundColor: Color(red: 0.9, green: 0.95, blue: 0.9),
        textColor: Color(red: 0.1, green: 0.3, blue: 0.1),
        accentColor: Color(red: 0.2, green: 0.6, blue: 0.2),
        fontSize: 16,
        fontFamily: "System",
        lineHeight: 1.5,
        pageMargin: 20,
        isDark: false
    )
    
    // MARK: - Theme Management
    func applyTheme(_ theme: ReadingTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
        saveCurrentTheme()
    }
    
    func getTheme(named name: String) -> ReadingTheme? {
        return availableThemes.first { $0.name == name } ?? 
               customThemes.first { $0.name == name }
    }
    
    func getAllThemes() -> [ReadingTheme] {
        return availableThemes + customThemes
    }
    
    // MARK: - Custom Themes
    func addCustomTheme(_ theme: ReadingTheme) {
        var customTheme = theme
        customTheme = ReadingTheme(
            name: theme.name,
            backgroundColor: theme.backgroundUIColor,
            textColor: theme.textUIColor,
            accentColor: theme.accentUIColor,
            fontSize: theme.fontSize,
            fontFamily: theme.fontFamily,
            lineHeight: theme.lineHeight,
            pageMargin: theme.pageMargin,
            isDark: theme.isDark,
            isCustom: true
        )
        
        customThemes.append(customTheme)
        saveCustomThemes()
    }
    
    func updateCustomTheme(_ theme: ReadingTheme) {
        if let index = customThemes.firstIndex(where: { $0.id == theme.id }) {
            customThemes[index] = theme
            saveCustomThemes()
            
            // 如果当前主题是被更新的主题，应用更改
            if currentTheme.id == theme.id {
                currentTheme = theme
                saveCurrentTheme()
            }
        }
    }
    
    func deleteCustomTheme(_ theme: ReadingTheme) {
        customThemes.removeAll { $0.id == theme.id }
        saveCustomThemes()
        
        // 如果删除的是当前主题，切换到默认主题
        if currentTheme.id == theme.id {
            applyTheme(Self.lightTheme)
        }
    }
    
    func duplicateTheme(_ theme: ReadingTheme, newName: String) {
        let duplicatedTheme = ReadingTheme(
            name: newName,
            backgroundColor: theme.backgroundUIColor,
            textColor: theme.textUIColor,
            accentColor: theme.accentUIColor,
            fontSize: theme.fontSize,
            fontFamily: theme.fontFamily,
            lineHeight: theme.lineHeight,
            pageMargin: theme.pageMargin,
            isDark: theme.isDark,
            isCustom: true
        )
        
        addCustomTheme(duplicatedTheme)
    }
    
    // MARK: - Theme Customization
    func updateFontSize(_ size: Double) {
        let updatedTheme = ReadingTheme(
            name: currentTheme.name,
            backgroundColor: currentTheme.backgroundUIColor,
            textColor: currentTheme.textUIColor,
            accentColor: currentTheme.accentUIColor,
            fontSize: size,
            fontFamily: currentTheme.fontFamily,
            lineHeight: currentTheme.lineHeight,
            pageMargin: currentTheme.pageMargin,
            isDark: currentTheme.isDark,
            isCustom: currentTheme.isCustom
        )
        
        applyTheme(updatedTheme)
        
        if currentTheme.isCustom {
            updateCustomTheme(updatedTheme)
        }
    }
    
    func updateLineHeight(_ height: Double) {
        let updatedTheme = ReadingTheme(
            name: currentTheme.name,
            backgroundColor: currentTheme.backgroundUIColor,
            textColor: currentTheme.textUIColor,
            accentColor: currentTheme.accentUIColor,
            fontSize: currentTheme.fontSize,
            fontFamily: currentTheme.fontFamily,
            lineHeight: height,
            pageMargin: currentTheme.pageMargin,
            isDark: currentTheme.isDark,
            isCustom: currentTheme.isCustom
        )
        
        applyTheme(updatedTheme)
        
        if currentTheme.isCustom {
            updateCustomTheme(updatedTheme)
        }
    }
    
    func updatePageMargin(_ margin: Double) {
        let updatedTheme = ReadingTheme(
            name: currentTheme.name,
            backgroundColor: currentTheme.backgroundUIColor,
            textColor: currentTheme.textUIColor,
            accentColor: currentTheme.accentUIColor,
            fontSize: currentTheme.fontSize,
            fontFamily: currentTheme.fontFamily,
            lineHeight: currentTheme.lineHeight,
            pageMargin: margin,
            isDark: currentTheme.isDark,
            isCustom: currentTheme.isCustom
        )
        
        applyTheme(updatedTheme)
        
        if currentTheme.isCustom {
            updateCustomTheme(updatedTheme)
        }
    }
    
    func updateFontFamily(_ family: String) {
        let updatedTheme = ReadingTheme(
            name: currentTheme.name,
            backgroundColor: currentTheme.backgroundUIColor,
            textColor: currentTheme.textUIColor,
            accentColor: currentTheme.accentUIColor,
            fontSize: currentTheme.fontSize,
            fontFamily: family,
            lineHeight: currentTheme.lineHeight,
            pageMargin: currentTheme.pageMargin,
            isDark: currentTheme.isDark,
            isCustom: currentTheme.isCustom
        )
        
        applyTheme(updatedTheme)
        
        if currentTheme.isCustom {
            updateCustomTheme(updatedTheme)
        }
    }
    
    // MARK: - Auto Theme
    func enableAutoTheme() {
        // 根据系统外观自动切换主题
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        let autoTheme = isDarkMode ? Self.darkTheme : Self.lightTheme
        applyTheme(autoTheme)
        
        userDefaults.set(true, forKey: "auto_theme_enabled")
    }
    
    func disableAutoTheme() {
        userDefaults.set(false, forKey: "auto_theme_enabled")
    }
    
    func isAutoThemeEnabled() -> Bool {
        return userDefaults.bool(forKey: "auto_theme_enabled")
    }
    
    // MARK: - Font Management
    func getAvailableFonts() -> [String] {
        return ["System", "Serif", "Monospace", "Georgia", "Times New Roman", "Helvetica", "Arial"]
    }
    
    func updateFontSettings(_ settings: FontSettings) {
        fontSettings = settings
        saveFontSettings()
    }
    
    // MARK: - Theme Import/Export
    func exportTheme(_ theme: ReadingTheme) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(theme)
    }
    
    func importTheme(from data: Data) throws -> ReadingTheme {
        let decoder = JSONDecoder()
        var theme = try decoder.decode(ReadingTheme.self, from: data)
        
        // 确保导入的主题是自定义主题
        theme = ReadingTheme(
            name: theme.name,
            backgroundColor: theme.backgroundUIColor,
            textColor: theme.textUIColor,
            accentColor: theme.accentUIColor,
            fontSize: theme.fontSize,
            fontFamily: theme.fontFamily,
            lineHeight: theme.lineHeight,
            pageMargin: theme.pageMargin,
            isDark: theme.isDark,
            isCustom: true
        )
        
        return theme
    }
    
    // MARK: - Theme Statistics
    func getThemeUsageStatistics() -> [String: Int] {
        // 这里可以记录主题使用统计
        return [:]
    }
    
    // MARK: - Persistence
    func saveCurrentTheme() {
        do {
            let data = try JSONEncoder().encode(currentTheme)
            userDefaults.set(data, forKey: "current_theme")
        } catch {
            print("保存当前主题失败: \(error)")
        }
    }
    
    func loadSavedTheme() {
        guard let data = userDefaults.data(forKey: "current_theme") else { return }
        
        do {
            currentTheme = try JSONDecoder().decode(ReadingTheme.self, from: data)
        } catch {
            print("加载保存的主题失败: \(error)")
            currentTheme = Self.lightTheme
        }
    }
    
    private func saveCustomThemes() {
        do {
            let data = try JSONEncoder().encode(customThemes)
            userDefaults.set(data, forKey: "custom_themes")
        } catch {
            print("保存自定义主题失败: \(error)")
        }
    }
    
    private func loadCustomThemes() {
        guard let data = userDefaults.data(forKey: "custom_themes") else { return }
        
        do {
            customThemes = try JSONDecoder().decode([ReadingTheme].self, from: data)
        } catch {
            print("加载自定义主题失败: \(error)")
        }
    }
    
    private func saveFontSettings() {
        do {
            let data = try JSONEncoder().encode(fontSettings)
            userDefaults.set(data, forKey: "font_settings")
        } catch {
            print("保存字体设置失败: \(error)")
        }
    }
    
    private func loadFontSettings() {
        guard let data = userDefaults.data(forKey: "font_settings") else { return }
        
        do {
            fontSettings = try JSONDecoder().decode(FontSettings.self, from: data)
        } catch {
            print("加载字体设置失败: \(error)")
        }
    }
}