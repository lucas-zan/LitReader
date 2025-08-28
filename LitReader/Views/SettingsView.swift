// LitReaderSwift/Views/SettingsView.swift
// 设置界面

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var settings = AppSettings.default
    @State private var showingClearDataAlert = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                // 阅读设置
                Section("阅读设置") {
                    NavigationLink("默认阅读主题") {
                        ReadingThemeSettingsView(theme: $settings.defaultReadingSettings)
                    }
                    
                    Toggle("自动保存进度", isOn: $settings.autoSave)
                }
                
                // 应用设置
                Section("应用设置") {
                    Picker("主题模式", selection: $settings.theme) {
                        Text("跟随系统").tag(AppSettings.AppTheme.auto)
                        Text("浅色模式").tag(AppSettings.AppTheme.light)
                        Text("深色模式").tag(AppSettings.AppTheme.dark)
                    }
                    
                    Picker("语言", selection: $settings.language) {
                        Text("中文").tag("zh")
                        Text("English").tag("en")
                    }
                }
                
                // 数据管理
                Section("数据管理") {
                    HStack {
                        Text("书籍数量")
                        Spacer()
                        Text("\(dataManager.library.books.count) 本")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("清空所有数据", role: .destructive) {
                        showingClearDataAlert = true
                    }
                }
                
                // 关于
                Section("关于") {
                    Button("关于 LitReader") {
                        showingAbout = true
                    }
                    
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            settings = dataManager.loadSettings()
        }
        .onChange(of: settings) { newSettings in
            dataManager.saveSettings(newSettings)
        }
        .alert("清空数据", isPresented: $showingClearDataAlert) {
            Button("取消", role: .cancel) { }
            Button("确认清空", role: .destructive) {
                dataManager.clearAllData()
            }
        } message: {
            Text("此操作将删除所有书籍和数据，且无法恢复。确定要继续吗？")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// MARK: - 阅读主题设置视图
struct ReadingThemeSettingsView: View {
    @Binding var theme: ReadingTheme
    
    var body: some View {
        Form {
            Section("字体设置") {
                HStack {
                    Text("字体大小")
                    Spacer()
                    Slider(value: $theme.fontSize, in: 12...24, step: 1)
                    Text("\(Int(theme.fontSize))")
                        .frame(width: 30)
                }
                
                HStack {
                    Text("行间距")
                    Spacer()
                    Slider(value: $theme.lineHeight, in: 1.0...2.0, step: 0.1)
                    Text(String(format: "%.1f", theme.lineHeight))
                        .frame(width: 30)
                }
                
                HStack {
                    Text("页边距")
                    Spacer()
                    Slider(value: $theme.pageMargin, in: 10...40, step: 5)
                    Text("\(Int(theme.pageMargin))")
                        .frame(width: 30)
                }
            }
            
            Section("预设主题") {
                ThemePresetRow(
                    title: "浅色",
                    backgroundColor: "#FFFFFF",
                    textColor: "#333333",
                    isSelected: theme.name == "light"
                ) {
                    setLightTheme()
                }
                
                ThemePresetRow(
                    title: "深色",
                    backgroundColor: "#1C1C1E",
                    textColor: "#FFFFFF",
                    isSelected: theme.name == "dark"
                ) {
                    setDarkTheme()
                }
                
                ThemePresetRow(
                    title: "护眼",
                    backgroundColor: "#F7F3E9",
                    textColor: "#5D4E37",
                    isSelected: theme.name == "sepia"
                ) {
                    setSepiaTheme()
                }
            }
            
            Section("预览") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("预览文本")
                        .font(.system(size: theme.fontSize))
                        .foregroundColor(theme.textUIColor)
                        .lineSpacing(theme.fontSize * (theme.lineHeight - 1))
                    
                    Text("这是一段示例文本，用于预览当前的阅读设置效果。您可以调整字体大小、行间距等参数来获得最佳的阅读体验。")
                        .font(.system(size: theme.fontSize))
                        .foregroundColor(theme.textUIColor)
                        .lineSpacing(theme.fontSize * (theme.lineHeight - 1))
                }
                .padding()
                .background(theme.backgroundUIColor)
                .cornerRadius(8)
            }
        }
        .navigationTitle("阅读主题")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func setLightTheme() {
        // TODO: 使用ThemeManager来设置主题
        print("设置浅色主题")
    }
    
    private func setDarkTheme() {
        // TODO: 使用ThemeManager来设置主题
        print("设置深色主题")
    }
    
    private func setSepiaTheme() {
        // TODO: 使用ThemeManager来设置主题
        print("设置护眼主题")
    }
}

// MARK: - 主题预设行
struct ThemePresetRow: View {
    let title: String
    let backgroundColor: String
    let textColor: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // 主题预览
                RoundedRectangle(cornerRadius: 6)
                    .fill(getColor(from: backgroundColor))
                    .overlay(
                        Text("Aa")
                            .font(.caption)
                            .foregroundColor(getColor(from: textColor))
                    )
                    .frame(width: 40, height: 30)
                    .cornerRadius(6)
                
                Text(title)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getColor(from hexString: String) -> Color {
        // 简单的颜色映射，实际项目中可以使用更复杂的解析
        switch hexString {
        case "#FFFFFF":
            return .white
        case "#1C1C1E":
            return Color(red: 0.11, green: 0.11, blue: 0.12)
        case "#F7F3E9":
            return Color(red: 0.97, green: 0.95, blue: 0.91)
        case "#333333":
            return Color(red: 0.2, green: 0.2, blue: 0.2)
        case "#FFFFFF":
            return .white
        case "#5D4E37":
            return Color(red: 0.36, green: 0.31, blue: 0.22)
        default:
            return .white
        }
    }
}

// AboutView 已在独立文件中定义

// MARK: - 功能特性行
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brown)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager.shared)
}