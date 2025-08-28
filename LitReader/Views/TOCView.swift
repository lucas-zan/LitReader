import SwiftUI

struct TOCView: View {
    let book: Book
    let content: String
    @Binding var currentPage: Int
    let totalPages: Int
    let dismissAction: () -> Void
    
    @EnvironmentObject var dataManager: DataManager
    @State private var generatedTOC: TableOfContents?
    @State private var isGenerating = false
    @State private var chapters: [Chapter] = []
    @State private var error: Error?
    
    var body: some View {
        NavigationView {
            ZStack {
                if isGenerating {
                    ProgressView("正在生成目录...")
                } else if let error = error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("生成目录失败")
                            .font(.headline)
                        
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("重试") {
                            generateTOC()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if chapters.isEmpty {
                    VStack {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("未检测到章节")
                            .font(.headline)
                        
                        Text("尝试不同的目录检测设置，或添加手动章节标记")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(chapters) { chapter in
                            ChapterRow(chapter: chapter, currentPage: currentPage, totalPages: totalPages)
                                .onTapGesture {
                                    jumpToChapter(chapter)
                                }
                        }
                    }
                }
            }
            .navigationTitle("目录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismissAction()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: generateTOC) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isGenerating)
                }
            }
            .onAppear {
                if generatedTOC == nil {
                    generateTOC()
                }
            }
        }
    }
    
    private func generateTOC() {
        isGenerating = true
        error = nil
        
        Task {
            do {
                let tocGenerator = TOCGenerator.shared
                let toc = try await tocGenerator.generateTOC(for: book, content: content)
                
                await MainActor.run {
                    self.generatedTOC = toc
                    self.chapters = toc.chapters
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isGenerating = false
                }
            }
        }
    }
    
    private func jumpToChapter(_ chapter: Chapter) {
        // 计算章节位置对应的页码
        let pageIndex = min(chapter.startPosition / 800, totalPages - 1)
        currentPage = max(0, pageIndex)
        dismissAction()
    }
}

struct ChapterRow: View {
    let chapter: Chapter
    let currentPage: Int
    let totalPages: Int
    
    // 计算当前阅读进度是否在该章节内
    private var isCurrentChapter: Bool {
        let currentPosition = currentPage * 800
        let endPosition = chapter.endPosition ?? (chapter.startPosition + 800)
        return currentPosition >= chapter.startPosition && currentPosition < endPosition
    }
    
    var body: some View {
        HStack {
            Text(chapter.formattedTitle)
                .font(.system(size: 16))
                .padding(.leading, CGFloat(chapter.level * 8))
                .foregroundColor(isCurrentChapter ? .blue : .primary)
                .fontWeight(isCurrentChapter ? .bold : .regular)
            
            Spacer()
            
            if let pageNumber = chapter.pageNumber {
                Text("P.\(pageNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}