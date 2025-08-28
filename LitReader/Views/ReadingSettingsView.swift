import SwiftUI

struct ReadingSettingsView: View {
    @Binding var settings: ReadingTheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var fontSizeTemp: Double
    @State private var lineHeightTemp: Double
    @State private var pageMarginTemp: Double
    @State private var selectedFont: String
    @State private var selectedThemeName: String = ""
    
    init(settings: Binding<ReadingTheme>) {
        self._settings = settings
        self._fontSizeTemp = State(initialValue: Double(settings.wrappedValue.fontSize))
        self._lineHeightTemp = State(initialValue: settings.wrappedValue.lineHeight)
        self._pageMarginTemp = State(initialValue: Double(settings.wrappedValue.pageMargin))
        self._selectedFont = State(initialValue: settings.wrappedValue.fontFamily)
        self._selectedThemeName = State(initialValue: settings.wrappedValue.name)
    }
    
    private let availableFonts = [
        "System",
        "Georgia",
        "Helvetica Neue",
        "Avenir Next",
        "Palatino",
        "Times New Roman"
    ]
    
    private let themes: [ReadingTheme] = [
        ReadingTheme(name: "默认浅色", backgroundColor: .white, textColor: .black, accentColor: .blue, fontSize: 16, fontFamily: "System", lineHeight: 1.5, pageMargin: 20, isDark: false),
        ReadingTheme(name: "纸张", backgroundColor: Color(red: 0.97, green: 0.95, blue: 0.91), textColor: Color(red: 0.2, green: 0.2, blue: 0.2), accentColor: .brown, fontSize: 16, fontFamily: "Georgia", lineHeight: 1.7, pageMargin: 24, isDark: false),
        ReadingTheme(name: "夜间", backgroundColor: Color(red: 0.11, green: 0.11, blue: 0.12), textColor: Color(red: 0.9, green: 0.9, blue: 0.9), accentColor: Color(red: 0.37, green: 0.36, blue: 0.84), fontSize: 16, fontFamily: "System", lineHeight: 1.6, pageMargin: 20, isDark: true),
        ReadingTheme(name: "护眼", backgroundColor: Color(red: 0.9, green: 0.94, blue: 0.85), textColor: Color(red: 0.2, green: 0.2, blue: 0.2), accentColor: .green, fontSize: 18, fontFamily: "Avenir Next", lineHeight: 1.8, pageMargin: 24, isDark: false),
        ReadingTheme(name: "墨水", backgroundColor: Color(red: 0.19, green: 0.19, blue: 0.19), textColor: Color(red: 0.79, green: 0.79, blue: 0.79), accentColor: Color(red: 0.31, green: 0.51, blue: 0.74), fontSize: 17, fontFamily: "Palatino", lineHeight: 1.6, pageMargin: 22, isDark: true)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("预设主题")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(themes, id: \.name) { theme in
                                ThemePreviewCard(
                                    theme: theme, 
                                    isSelected: theme.name == selectedThemeName,
                                    showActions: false
                                ) {
                                    applyTheme(theme)
                                }
                                .onTapGesture {
                                    selectedThemeName = theme.name
                                    applyTheme(theme)
                                }
                                .scaleEffect(theme.name == selectedThemeName ? 0.95 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: theme.name == selectedThemeName)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                
                Section(header: Text("字体")) {
                    Picker("字体", selection: $selectedFont) {
                        ForEach(availableFonts, id: \.self) { font in
                            Text(font)
                                .font(getFont(family: font))
                        }
                    }
                    .onChange(of: selectedFont) { newValue in
                        settings.fontFamily = newValue
                    }
                }
                
                Section(header: Text("字体大小 (\(Int(fontSizeTemp)))")) {
                    Slider(value: $fontSizeTemp, in: 12...24, step: 1)
                        .onChange(of: fontSizeTemp) { newValue in
                            settings.fontSize = newValue
                        }
                }
                
                Section(header: Text("行高 (x\(String(format: "%.1f", lineHeightTemp)))")) {
                    Slider(value: $lineHeightTemp, in: 1.0...2.0, step: 0.1)
                        .onChange(of: lineHeightTemp) { newValue in
                            settings.lineHeight = newValue
                        }
                }
                
                Section(header: Text("页面边距 (\(Int(pageMarginTemp)))")) {
                    Slider(value: $pageMarginTemp, in: 10...40, step: 2)
                        .onChange(of: pageMarginTemp) { newValue in
                            settings.pageMargin = newValue
                        }
                }
                
                Section(header: Text("颜色")) {
                    ColorPicker("背景色", selection: Binding(
                        get: { settings.backgroundColor.color },
                        set: { settings.backgroundColor = CodableColor($0) }
                    ))
                    
                    ColorPicker("文字颜色", selection: Binding(
                        get: { settings.textColor.color },
                        set: { settings.textColor = CodableColor($0) }
                    ))
                    
                    ColorPicker("强调色", selection: Binding(
                        get: { settings.accentColor.color },
                        set: { settings.accentColor = CodableColor($0) }
                    ))
                }
                
                Section {
                    Button("恢复默认设置") {
                        let defaultTheme = AppSettings.default.defaultReadingSettings
                        settings = defaultTheme
                        fontSizeTemp = Double(defaultTheme.fontSize)
                        lineHeightTemp = defaultTheme.lineHeight
                        pageMarginTemp = Double(defaultTheme.pageMargin)
                        selectedFont = defaultTheme.fontFamily
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("阅读设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        // 确保在关闭前应用所有更改
                        settings.fontSize = fontSizeTemp
                        settings.lineHeight = lineHeightTemp
                        settings.pageMargin = pageMarginTemp
                        settings.fontFamily = selectedFont
                        dismiss()
                    }
                }
            }
            .onDisappear {
                // 确保视图消失时也应用所有更改
                settings.fontSize = fontSizeTemp
                settings.lineHeight = lineHeightTemp
                settings.pageMargin = pageMarginTemp
                settings.fontFamily = selectedFont
            }
        }
    }
    
    private func applyTheme(_ theme: ReadingTheme) {
        settings = theme
        fontSizeTemp = Double(theme.fontSize)
        lineHeightTemp = theme.lineHeight
        pageMarginTemp = Double(theme.pageMargin)
        selectedFont = theme.fontFamily
    }
    
    private func getFont(family: String) -> Font {
        Font.custom(family, size: 16)
    }
}





#Preview {
    NavigationView {
        ReadingSettingsView(settings: .constant(AppSettings.default.defaultReadingSettings))
    }
}