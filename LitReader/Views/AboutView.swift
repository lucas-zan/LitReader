import SwiftUI

struct AboutView: View {
    @EnvironmentObject var navigationSystem: NavigationSystem
    @State private var showingLicenses = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 应用图标和名称
                appHeaderSection
                
                // 版本信息
                versionInfoSection
                
                // 开发团队
                developerSection
                
                // 功能特色
                featuresSection
                
                // 法律信息
                legalSection
                
                // 联系方式
                contactSection
                
                // 感谢
                acknowledgementsSection
            }
            .padding()
        }
        .navigationTitle("关于LitReader")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingLicenses) {
            LicensesView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            WebView(url: "https://example.com/privacy")
        }
        .sheet(isPresented: $showingTermsOfService) {
            WebView(url: "https://example.com/terms")
        }
    }
    
    // MARK: - 应用头部
    private var appHeaderSection: some View {
        VStack(spacing: 16) {
            // 应用图标
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                )
            
            VStack(spacing: 4) {
                Text("LitReader")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("优雅的阅读体验")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - 版本信息
    private var versionInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("版本信息")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                InfoRow(title: "版本", value: getAppVersion())
                Divider().padding(.leading)
                InfoRow(title: "构建版本", value: getBuildNumber())
                Divider().padding(.leading)
                InfoRow(title: "发布日期", value: "2024年8月")
                Divider().padding(.leading)
                InfoRow(title: "最低系统要求", value: "iOS 15.0+")
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 开发团队
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("开发团队")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                DeveloperCard(
                    name: "LitReader Team",
                    role: "iOS应用开发",
                    description: "专注于为用户提供优质的阅读体验",
                    icon: "person.3"
                )
                
                DeveloperCard(
                    name: "UI/UX Design",
                    role: "界面设计",
                    description: "简洁优雅的用户界面设计",
                    icon: "paintbrush"
                )
                
                DeveloperCard(
                    name: "Backend Support",
                    role: "后端支持",
                    description: "云同步和数据安全保障",
                    icon: "server.rack"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 功能特色
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("主要功能")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                FeatureCard(
                    icon: "doc.text.viewfinder",
                    title: "多格式支持",
                    description: "支持TXT、EPUB、PDF等格式"
                )
                
                FeatureCard(
                    icon: "bookmark",
                    title: "智能书签",
                    description: "分类管理，快速定位"
                )
                
                FeatureCard(
                    icon: "magnifyingglass",
                    title: "全文搜索",
                    description: "强大的搜索和正则表达式支持"
                )
                
                FeatureCard(
                    icon: "paintbrush",
                    title: "个性主题",
                    description: "多种预设主题，护眼阅读"
                )
                
                FeatureCard(
                    icon: "icloud",
                    title: "云端同步",
                    description: "多设备同步阅读进度"
                )
                
                FeatureCard(
                    icon: "brain.head.profile",
                    title: "AI助手",
                    description: "智能摘要和阅读建议"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 法律信息
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("法律信息")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                Button {
                    showingPrivacyPolicy = true
                } label: {
                    LegalRow(title: "隐私政策", icon: "hand.raised")
                }
                
                Divider().padding(.leading)
                
                Button {
                    showingTermsOfService = true
                } label: {
                    LegalRow(title: "服务条款", icon: "doc.text")
                }
                
                Divider().padding(.leading)
                
                Button {
                    showingLicenses = true
                } label: {
                    LegalRow(title: "开源许可", icon: "heart")
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 联系方式
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("联系我们")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                Button {
                    sendEmail()
                } label: {
                    ContactRow(
                        title: "发送邮件",
                        subtitle: "support@litreader.com",
                        icon: "envelope"
                    )
                }
                
                Divider().padding(.leading)
                
                Button {
                    openWebsite()
                } label: {
                    ContactRow(
                        title: "官方网站",
                        subtitle: "www.litreader.com",
                        icon: "globe"
                    )
                }
                
                Divider().padding(.leading)
                
                Button {
                    openGitHub()
                } label: {
                    ContactRow(
                        title: "GitHub",
                        subtitle: "github.com/litreader",
                        icon: "chevron.left.forwardslash.chevron.right"
                    )
                }
                
                Divider().padding(.leading)
                
                Button {
                    rateApp()
                } label: {
                    ContactRow(
                        title: "评价应用",
                        subtitle: "App Store",
                        icon: "star"
                    )
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 致谢
    private var acknowledgementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("特别感谢")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                AcknowledgementItem(
                    title: "SwiftUI",
                    description: "Apple的现代UI框架",
                    url: "https://developer.apple.com/swiftui/"
                )
                
                AcknowledgementItem(
                    title: "Combine",
                    description: "Apple的响应式编程框架",
                    url: "https://developer.apple.com/documentation/combine"
                )
                
                AcknowledgementItem(
                    title: "开源社区",
                    description: "感谢所有开源项目贡献者",
                    url: nil
                )
                
                AcknowledgementItem(
                    title: "测试用户",
                    description: "感谢所有提供反馈的用户",
                    url: nil
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 辅助方法
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    private func sendEmail() {
        if let emailURL = URL(string: "mailto:support@litreader.com?subject=LitReader反馈") {
            UIApplication.shared.open(emailURL)
        }
    }
    
    private func openWebsite() {
        if let websiteURL = URL(string: "https://www.litreader.com") {
            UIApplication.shared.open(websiteURL)
        }
    }
    
    private func openGitHub() {
        if let githubURL = URL(string: "https://github.com/litreader") {
            UIApplication.shared.open(githubURL)
        }
    }
    
    private func rateApp() {
        // TODO: 实现App Store评价功能
        if let appStoreURL = URL(string: "https://apps.apple.com/app/id123456789") {
            UIApplication.shared.open(appStoreURL)
        }
    }
}

// MARK: - 辅助视图组件
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .padding()
    }
}

struct DeveloperCard: View {
    let name: String
    let role: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(role)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct LegalRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ContactRow: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "arrow.up.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct AcknowledgementItem: View {
    let title: String
    let description: String
    let url: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let url = url, let validURL = URL(string: url) {
                Button {
                    UIApplication.shared.open(validURL)
                } label: {
                    HStack {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                }
            } else {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 许可证视图
struct LicensesView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let licenses = [
        License(
            name: "SwiftUI",
            description: "Apple Inc.",
            license: "Apple Software License Agreement"
        ),
        License(
            name: "Combine",
            description: "Apple Inc.",
            license: "Apple Software License Agreement"
        ),
        License(
            name: "Foundation",
            description: "Apple Inc.",
            license: "Apple Software License Agreement"
        )
    ]
    
    var body: some View {
        NavigationView {
            List(licenses) { license in
                VStack(alignment: .leading, spacing: 8) {
                    Text(license.name)
                        .font(.headline)
                    
                    Text(license.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(license.license)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("开源许可")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct License: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let license: String
}

// MARK: - 网页视图
struct WebView: View {
    let url: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            // TODO: 实现WebView
            VStack {
                Text("网页内容")
                Text(url)
                    .foregroundColor(.blue)
            }
            .navigationTitle("网页")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView()
        }
        .environmentObject(NavigationSystem.shared)
    }
}