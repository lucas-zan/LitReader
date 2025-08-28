import SwiftUI

struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navigationSystem: NavigationSystem
    
    @State private var showingCustomThemeEditor = false
    @State private var selectedThemeForPreview: ReadingTheme?
    @State private var showingThemePreview = false
    @State private var isEditingMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 当前主题预览
            currentThemePreview
            
            // 主题列表
            themesList
        }
        .navigationTitle("主题设置")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(isEditingMode ? "完成" : "编辑") {
                    withAnimation {
                        isEditingMode.toggle()
                    }
                }
                
                Button {
                    showingCustomThemeEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCustomThemeEditor) {
            CustomThemeEditorView()
        }
        .sheet(isPresented: $showingThemePreview) {
            if let theme = selectedThemeForPreview {
                ThemePreviewView(theme: theme)
            }
        }
    }
    
    // MARK: - 当前主题预览
    private var currentThemePreview: some View {
        VStack(spacing: 16) {
            Text("当前主题")
                .font(.headline)
                .foregroundColor(.primary)
            
            ThemePreviewCard(
                theme: themeManager.currentTheme,
                isSelected: true,
                showActions: false
            ) {
                // 当前主题不需要点击操作
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - 主题列表
    private var themesList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // 预设主题
                presetThemesSection
                
                // 自定义主题
                customThemesSection
            }
            .padding()
        }
    }
    
    // MARK: - 预设主题部分
    private var presetThemesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("预设主题")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(themeManager.availableThemes, id: \.name) { theme in
                    ThemePreviewCard(
                        theme: theme,
                        isSelected: themeManager.currentTheme.name == theme.name,
                        showActions: false
                    ) {
                        selectTheme(theme)
                    }
                }
            }
        }
    }
    
    // MARK: - 自定义主题部分
    private var customThemesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("自定义主题")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !themeManager.customThemes.isEmpty && isEditingMode {
                    Text("选择要删除的主题")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if themeManager.customThemes.isEmpty {
                EmptyCustomThemesView {
                    showingCustomThemeEditor = true
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(themeManager.customThemes, id: \.name) { theme in
                        ThemePreviewCard(
                            theme: theme,
                            isSelected: themeManager.currentTheme.name == theme.name,
                            showActions: true,
                            isEditing: isEditingMode
                        ) {
                            if isEditingMode {
                                // 编辑模式下显示删除选项
                                showDeleteConfirmation(for: theme)
                            } else {
                                selectTheme(theme)
                            }
                        }
                        .contextMenu {
                            if !isEditingMode {
                                Button {
                                    selectedThemeForPreview = theme
                                    showingThemePreview = true
                                } label: {
                                    Label("预览", systemImage: "eye")
                                }
                                
                                Button {
                                    editTheme(theme)
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    showDeleteConfirmation(for: theme)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    private func selectTheme(_ theme: ReadingTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            themeManager.applyTheme(theme)
        }
    }
    
    private func editTheme(_ theme: ReadingTheme) {
        // TODO: 实现主题编辑功能
        showingCustomThemeEditor = true
    }
    
    private func showDeleteConfirmation(for theme: ReadingTheme) {
        // TODO: 显示删除确认对话框
        themeManager.deleteCustomTheme(theme)
    }
}

// MARK: - 主题预览卡片
struct ThemePreviewCard: View {
    let theme: ReadingTheme
    let isSelected: Bool
    let showActions: Bool
    var isEditing: Bool = false
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 12) {
                // 主题预览
                themePreview
                
                // 主题信息
                themeInfo
                
                // 选中状态指示器
                if isSelected && !isEditing {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("当前使用")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                // 编辑模式删除按钮
                if showActions && isEditing {
                    Button {
                        onTap()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("删除")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.blue : Color(.systemGray4),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
    
    private var themePreview: some View {
        VStack(spacing: 8) {
            // 主题预览内容
            ZStack {
                // 模拟阅读界面
                VStack(alignment: .leading, spacing: 6) {
                    // 标题行
                    Rectangle()
                        .fill(theme.textUIColor)
                        .frame(height: 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 内容行
                    HStack {
                        Rectangle()
                            .fill(theme.textUIColor.opacity(0.8))
                            .frame(width: 60, height: 3)
                        
                        Rectangle()
                            .fill(theme.textUIColor.opacity(0.6))
                            .frame(width: 40, height: 3)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Rectangle()
                            .fill(theme.textUIColor.opacity(0.7))
                            .frame(width: 80, height: 3)
                        
                        Rectangle()
                            .fill(theme.textUIColor.opacity(0.5))
                            .frame(width: 30, height: 3)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Rectangle()
                            .fill(theme.textUIColor.opacity(0.6))
                            .frame(width: 70, height: 3)
                        
                        Spacer()
                    }
                }
                .padding(8)
                .background(theme.backgroundUIColor)
                .cornerRadius(6)
                .frame(height: 60)
                
                // 右上角选中标识 - 改进版本，使用ZStack的overlay
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Circle()
                                .fill(Color.green)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                .padding(5)
                            
                        }
                        Spacer()
                    }
                }
            }
        }
        .overlay(
            // 整个卡片的边框高亮
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private var themeInfo: some View {
        VStack(spacing: 4) {
            Text(getDisplayName(for: theme))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(theme.backgroundUIColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
                
                Circle()
                    .fill(theme.textUIColor)
                    .frame(width: 12, height: 12)
                
                Text("\(Int(theme.fontSize))pt")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getDisplayName(for theme: ReadingTheme) -> String {
        switch theme.name {
        case "light":
            return "经典白天"
        case "dark":
            return "深邃夜间"
        case "sepia":
            return "温馨护眼"
        case "night":
            return "夜间模式"
        case "paper":
            return "纸质书感"
        case "green":
            return "自然清新"
        default:
            return theme.name
        }
    }
}

// MARK: - 空自定义主题视图
struct EmptyCustomThemesView: View {
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "paintbrush")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("暂无自定义主题")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("创建属于您的个性化阅读主题")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                onCreate()
            } label: {
                Text("创建主题")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 自定义主题编辑器
struct CustomThemeEditorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var themeName = ""
    @State private var backgroundColor = Color.white
    @State private var textColor = Color.black
    @State private var fontSize: Double = 16
    @State private var fontFamily = "System"
    @State private var lineHeight: Double = 1.5
    @State private var pageMargin: Double = 20
    
    private let fontFamilies = ["System", "Times New Roman", "Georgia", "Helvetica", "Arial"]
    
    var previewTheme: ReadingTheme {
        ReadingTheme(
            name: themeName.isEmpty ? "预览主题" : themeName,
            backgroundColor: backgroundColor,
            textColor: textColor,
            accentColor: .blue,  // 添加缺失的accentColor参数
            fontSize: fontSize,
            fontFamily: fontFamily,
            lineHeight: lineHeight,
            pageMargin: pageMargin
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 实时预览
                themePreviewSection
                
                Divider()
                
                // 编辑表单
                themeEditorForm
            }
            .navigationTitle("创建主题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTheme()
                    }
                    .disabled(themeName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - 主题预览部分
    private var themePreviewSection: some View {
        VStack(spacing: 12) {
            Text("实时预览")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 模拟阅读页面
            VStack(alignment: .leading, spacing: CGFloat(lineHeight * fontSize / 2)) {
                Text("示例章节标题")
                    .font(.system(size: fontSize + 2, weight: .bold))
                    .foregroundColor(textColor)
                
                Text("这是一段示例文本，用于预览当前主题的显示效果。您可以看到字体大小、颜色、行间距等设置的实际效果。")
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
                    .lineSpacing(CGFloat(lineHeight * fontSize - fontSize))
                
                Text("通过调整各项参数，您可以创建最适合自己的阅读主题，提升阅读体验。")
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
                    .lineSpacing(CGFloat(lineHeight * fontSize - fontSize))
            }
            .padding(CGFloat(pageMargin))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .padding()
    }
    
    // MARK: - 主题编辑表单
    private var themeEditorForm: some View {
        Form {
            Section("基本信息") {
                TextField("主题名称", text: $themeName)
                    .textInputAutocapitalization(.words)
            }
            
            Section("颜色设置") {
                ColorPicker("背景颜色", selection: $backgroundColor)
                ColorPicker("文字颜色", selection: $textColor)
            }
            
            Section("字体设置") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("字体大小")
                        Spacer()
                        Text("\(Int(fontSize))pt")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $fontSize, in: 12...24, step: 1)
                }
                
                Picker("字体", selection: $fontFamily) {
                    ForEach(fontFamilies, id: \.self) { family in
                        Text(family).tag(family)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("行间距")
                        Spacer()
                        Text(String(format: "%.1f", lineHeight))
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $lineHeight, in: 1.0...2.5, step: 0.1)
                }
            }
            
            Section("页面设置") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("页边距")
                        Spacer()
                        Text("\(Int(pageMargin))px")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $pageMargin, in: 10...40, step: 5)
                }
            }
            
            Section("快速设置") {
                Button("护眼模式") {
                    applyEyeProtectionSettings()
                }
                
                Button("夜间模式") {
                    applyNightModeSettings()
                }
                
                Button("经典模式") {
                    applyClassicSettings()
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    private func saveTheme() {
        let newTheme = ReadingTheme(
            name: themeName,
            backgroundColor: backgroundColor,
            textColor: textColor,
            accentColor: .blue,  // 添加缺失的accentColor参数
            fontSize: fontSize,
            fontFamily: fontFamily,
            lineHeight: lineHeight,
            pageMargin: pageMargin
        )
        
        themeManager.addCustomTheme(newTheme)
        dismiss()
    }
    
    private func applyEyeProtectionSettings() {
        backgroundColor = Color(red: 0.96, green: 0.95, blue: 0.87) // 护眼黄
        textColor = Color(red: 0.2, green: 0.2, blue: 0.1)
        fontSize = 16
        lineHeight = 1.6
    }
    
    private func applyNightModeSettings() {
        backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.1)
        textColor = Color(red: 0.8, green: 0.8, blue: 0.8)
        fontSize = 16
        lineHeight = 1.5
    }
    
    private func applyClassicSettings() {
        backgroundColor = Color.white
        textColor = Color.black
        fontSize = 16
        lineHeight = 1.5
        pageMargin = 20
    }
}

// MARK: - 主题预览视图
struct ThemePreviewView: View {
    let theme: ReadingTheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: CGFloat(theme.lineHeight * theme.fontSize / 2)) {
                    Text("第一章 开始")
                        .font(.system(size: theme.fontSize + 4, weight: .bold))
                        .foregroundColor(theme.textUIColor)
                    
                    Text("这是一个完整的主题预览页面。在这里您可以体验完整的阅读效果，包括字体大小、颜色搭配、行间距等所有设置。")
                        .font(.system(size: theme.fontSize))
                        .foregroundColor(theme.textUIColor)
                        .lineSpacing(CGFloat(theme.lineHeight * theme.fontSize - theme.fontSize))
                    
                    Text("长期阅读时，合适的主题设置能够有效减少眼部疲劳，提升阅读舒适度。您可以根据不同的阅读环境和个人喜好选择或创建最适合的主题。")
                        .font(.system(size: theme.fontSize))
                        .foregroundColor(theme.textUIColor)
                        .lineSpacing(CGFloat(theme.lineHeight * theme.fontSize - theme.fontSize))
                    
                    Text("如果您对当前主题满意，可以点击右上角的<应用>按钮将其设为默认主题。")
                        .font(.system(size: theme.fontSize))
                        .foregroundColor(theme.textUIColor)
                        .lineSpacing(CGFloat(theme.lineHeight * theme.fontSize - theme.fontSize))
                }
                .padding(CGFloat(theme.pageMargin))
            }
            .background(theme.backgroundUIColor)
            .navigationTitle("主题预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("应用") {
                        themeManager.applyTheme(theme)
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Preview
struct ThemeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ThemeSelectionView()
        }
        .environmentObject(ThemeManager.shared)
        .environmentObject(NavigationSystem.shared)
    }
}
