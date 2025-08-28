import SwiftUI
import UniformTypeIdentifiers

struct ImportBooksView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var bookParser: BookParser
    @EnvironmentObject var fileImporter: FileImporter
    @EnvironmentObject var navigationSystem: NavigationSystem
    
    @State private var showingFilePicker = false
    @State private var showingDocumentPicker = false
    @State private var showingURLImporter = false
    @State private var isImporting = false
    @State private var importProgress: Double = 0.0
    @State private var importStatus = ""
    @State private var importedBooks: [Book] = []
    @State private var importErrors: [ImportError] = []
    @State private var showingErrorDetails = false
    
    struct ImportError: Identifiable {
        let id = UUID()
        let fileName: String
        let error: String
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 导入方式选择
                importMethodsSection
                
                // 导入进度
                if isImporting {
                    importProgressSection
                }
                
                // 导入结果
                if !importedBooks.isEmpty || !importErrors.isEmpty {
                    importResultsSection
                }
                
                // 使用指南
                if !isImporting && importedBooks.isEmpty {
                    importGuideSection
                }
                
                // 模拟器专用功能（仅在模拟器中显示）
                #if targetEnvironment(simulator)
                simulatorFeaturesSection
                #endif
            }
            .padding()
        }
        .navigationTitle("导入书籍")
        .navigationBarTitleDisplayMode(.large)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.plainText, .epub, .pdf],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        #if targetEnvironment(simulator)
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.plainText, .epub, .pdf],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        #endif
        .sheet(isPresented: $showingURLImporter) {
            URLImporterView { urls in
                importFromURLs(urls)
            }
        }
        .alert("导入错误", isPresented: $showingErrorDetails) {
            Button("确定") { }
        } message: {
            if let firstError = importErrors.first {
                Text(firstError.error)
            }
        }
    }
    
    // MARK: - 导入方式选择
    private var importMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择导入方式")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ImportMethodCard(
                    icon: "folder",
                    title: "从文件选择",
                    description: "浏览并选择设备上的电子书文件",
                    color: .blue
                ) {
                    showingFilePicker = true
                }
                
                ImportMethodCard(
                    icon: "icloud.and.arrow.down",
                    title: "从云存储导入",
                    description: "从iCloud Drive等云服务导入",
                    color: .green
                ) {
                    showingDocumentPicker = true
                }
                
                ImportMethodCard(
                    icon: "link",
                    title: "从网址导入",
                    description: "通过URL下载电子书",
                    color: .orange
                ) {
                    showingURLImporter = true
                }
                
                ImportMethodCard(
                    icon: "square.and.arrow.down",
                    title: "从其他应用",
                    description: "通过分享功能导入书籍",
                    color: .purple
                ) {
                    // TODO: 显示分享导入说明
                }
            }
            
            // 仅在模拟器中显示的特殊功能
            #if targetEnvironment(simulator)
            simulatorFeaturesSection
            #endif
        }
    }
    
    // MARK: - 模拟器专用功能（仅在模拟器中显示）
    #if targetEnvironment(simulator)
    private var simulatorFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("模拟器专用功能")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                Button {
                    importFromDesktop()
                } label: {
                    HStack {
                        Image(systemName: "desktopcomputer")
                        Text("从Mac桌面导入")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Text("直接导入Mac桌面上的电子书文件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    #endif
    
    // MARK: - 导入进度部分
    private var importProgressSection: some View {
        VStack(spacing: 16) {
            Text("正在导入...")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ProgressView(value: importProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                Text(importStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 导入结果部分
    private var importResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("导入结果")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 成功导入的书籍
            if !importedBooks.isEmpty {
                successfulImportsView
            }
            
            // 导入错误
            if !importErrors.isEmpty {
                importErrorsView
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                if !importedBooks.isEmpty {
                    Button {
                        Task {
                            try await navigationSystem.navigate(to: .library)
                        }
                    } label: {
                        Text("查看书库")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                
                Button {
                    resetImportState()
                } label: {
                    Text("继续导入")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - 成功导入视图
    private var successfulImportsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("成功导入 \(importedBooks.count) 本书籍")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(importedBooks.prefix(5)) { book in
                    ImportedBookRow(book: book)
                }
                
                if importedBooks.count > 5 {
                    Text("还有 \(importedBooks.count - 5) 本书籍...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 导入错误视图
    private var importErrorsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("导入失败 \(importErrors.count) 个文件")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Button("查看详情") {
                    showingErrorDetails = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 4) {
                ForEach(importErrors.prefix(3)) { error in
                    HStack {
                        Text(error.fileName)
                            .font(.caption)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(error.error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if importErrors.count > 3 {
                    Text("还有 \(importErrors.count - 3) 个错误...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 使用指南部分
    private var importGuideSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("使用指南")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                GuideItem(
                    icon: "doc.text",
                    title: "支持的文件格式",
                    description: "TXT、EPUB、PDF等主流电子书格式"
                )
                
                GuideItem(
                    icon: "magnifyingglass",
                    title: "文件选择提示",
                    description: "在文件选择器中，您可以浏览设备上的所有文件。如果找不到文件，请确保文件已同步到设备或云存储中。"
                )
                
                GuideItem(
                    icon: "square.and.arrow.down",
                    title: "从其他应用导入",
                    description: "在其他应用中选择<分享到LitReader>来快速导入"
                )
                
                GuideItem(
                    icon: "icloud",
                    title: "云存储同步",
                    description: "导入的书籍可以自动同步到您的其他设备"
                )
                
                GuideItem(
                    icon: "bookmark",
                    title: "自动处理",
                    description: "导入后会自动提取封面、目录等信息"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // 技巧提示
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                    Text("小贴士")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• 建议文件名使用中文或英文，避免特殊字符")
                    Text("• 大文件导入可能需要较长时间，请耐心等待")
                    Text("• PDF文件支持有限，建议使用EPUB或TXT格式")
                    Text("• 可以同时选择多个文件进行批量导入")
                    Text("• 在模拟器中，您可以将文件放在Mac桌面上，然后在文件选择器中导航到桌面")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
            
            // 模拟器环境说明
            #if targetEnvironment(simulator)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("模拟器环境说明")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• 在模拟器中运行时，文件选择器可能显示的是连接的真机设备内容")
                    Text("• 建议将文件放在Mac桌面上，然后在文件选择器中导航到桌面")
                    Text("• 您也可以通过拖放方式将文件直接放入模拟器窗口")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            #endif
        }
    }
    
    // MARK: - 导入处理方法
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            importFromURLs(urls)
        case .failure(let error):
            importErrors.append(ImportError(fileName: "文件选择", error: error.localizedDescription))
        }
    }
    
    private func importFromURLs(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        isImporting = true
        importProgress = 0.0
        importedBooks.removeAll()
        importErrors.removeAll()
        
        Task {
            for (index, url) in urls.enumerated() {
                await MainActor.run {
                    importStatus = "正在导入: \(url.lastPathComponent) (\(index + 1)/\(urls.count))"
                    importProgress = Double(index) / Double(urls.count)
                }
                
                do {
                    // 确保可以访问文件
                    let _ = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    let book = try await bookParser.parseFile(at: url)
                    dataManager.addBook(book)  // 移除await，因为addBook不是异步方法
                    
                    await MainActor.run {
                        importedBooks.append(book)
                    }
                } catch {
                    await MainActor.run {
                        importErrors.append(ImportError(
                            fileName: url.lastPathComponent,
                            error: error.localizedDescription
                        ))
                    }
                }
            }
            
            await MainActor.run {
                importProgress = 1.0
                importStatus = "导入完成"
                isImporting = false
            }
        }
    }
    
    private func resetImportState() {
        importedBooks.removeAll()
        importErrors.removeAll()
        importProgress = 0.0
        importStatus = ""
    }
}

// MARK: - 辅助视图组件
struct ImportMethodCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ImportedBookRow: View {
    let book: Book
    
    var body: some View {
        HStack {
            Image(systemName: "book.closed")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let author = book.author {
                    Text(author)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(book.format.rawValue.uppercased())
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
        }
    }
}

struct GuideItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - URL导入器
struct URLImporterView: View {
    let onImport: ([URL]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var urlText = ""
    @State private var urls: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("输入电子书下载链接")
                    .font(.headline)
                    .padding(.top)
                
                TextField("https://example.com/book.epub", text: $urlText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button("添加链接") {
                    addURL()
                }
                .disabled(urlText.isEmpty)
                
                if !urls.isEmpty {
                    List {
                        ForEach(urls, id: \.self) { url in
                            Text(url)
                                .font(.caption)
                        }
                        .onDelete { indexSet in
                            urls.remove(atOffsets: indexSet)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("从URL导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("导入") {
                        startImport()
                    }
                    .disabled(urls.isEmpty)
                }
            }
        }
    }
    
    private func addURL() {
        guard !urlText.isEmpty, let _ = URL(string: urlText) else { return }
        urls.append(urlText)
        urlText = ""
    }
    
    private func startImport() {
        let validURLs = urls.compactMap { URL(string: $0) }
        onImport(validURLs)
        dismiss()
    }
}

// MARK: - 扩展
extension UTType {
    static let epub = UTType(filenameExtension: "epub")!
}

#if targetEnvironment(simulator)
extension ImportBooksView {
    private func importFromDesktop() {
        // 在模拟器中直接访问Mac桌面目录
        // 注意：iOS中不能直接访问Mac桌面，我们需要使用模拟器特定的方法
        #if targetEnvironment(simulator)
        // 在模拟器中，我们可以通过特殊路径访问Mac的桌面
        let desktopPath = "/Users/\(NSUserName())/Desktop"
        let desktopURL = URL(fileURLWithPath: desktopPath)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: desktopURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: .skipsHiddenFiles
            )
            
            // 过滤出支持的文件格式
            let supportedFiles = fileURLs.filter { url in
                let pathExtension = url.pathExtension.lowercased()
                return ["txt", "epub", "pdf"].contains(pathExtension)
            }
            
            // 导入所有支持的文件
            importFromURLs(supportedFiles)
        } catch {
            importErrors.append(ImportError(
                fileName: "桌面导入",
                error: "无法访问桌面目录: \(error.localizedDescription)"
            ))
        }
        #endif
    }
}
#endif

// MARK: - Preview
struct ImportBooksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ImportBooksView()
        }
        .environmentObject(DataManager.shared)
        .environmentObject(BookParser.shared)
        .environmentObject(FileImporter.shared)
        .environmentObject(NavigationSystem.shared)
    }
}