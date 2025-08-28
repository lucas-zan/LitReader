# LitReader

一款专为iOS设计的智能文学阅读器，支持多种格式，提供AI驱动的阅读体验。

[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg)](https://developer.apple.com/xcode/swiftui/)

## 📖 项目简介

LitReader 是一款现代化的iOS文学阅读应用，专注于为用户提供沉浸式的阅读体验。应用集成了先进的AI技术，不仅支持传统的阅读功能，还能智能分析文本内容，提供个性化的阅读建议和深度洞察。

### 🎯 项目愿景

- **智能化阅读**：利用AI技术提升阅读体验，提供智能摘要、情感分析等功能
- **个性化体验**：根据用户阅读习惯提供定制化的界面和推荐
- **多格式支持**：无缝支持TXT、EPUB、PDF等主流电子书格式
- **优雅设计**：采用现代化的SwiftUI界面，提供流畅的用户体验

## ✨ 核心功能

### 📚 阅读管理
- **多格式支持**：TXT、EPUB、PDF文件完美兼容
- **智能书库**：自动扫描和管理本地图书
- **阅读进度**：精确记录阅读位置和进度
- **书签系统**：快速标记和跳转到重要内容
- **搜索功能**：全文搜索，快速定位内容

### 🤖 AI智能功能
- **智能摘要**：AI自动生成文章要点和总结
- **情感分析**：分析文本的情感倾向和情绪曲线
- **阅读洞察**：基于阅读习惯提供个性化建议
- **智能推荐**：推荐相似类型的优质内容
- **可读性评估**：评估文本难度和阅读水平

### 🎨 个性化体验
- **多主题支持**：深色/浅色主题，护眼模式
- **阅读设置**：字体大小、行间距、页边距自定义
- **统计分析**：阅读时长、进度统计
- **云端同步**：跨设备数据同步（规划中）

### 📊 数据管理
- **本地存储**：安全的本地数据管理
- **导入导出**：便捷的文件导入和数据备份
- **性能优化**：大文件快速加载和流畅翻页
- **隐私保护**：用户数据完全本地化处理

## 🏗️ 技术架构

### 技术栈
- **开发语言**：Swift 5.0+
- **UI框架**：SwiftUI
- **最低支持**：iOS 15.0+
- **开发工具**：Xcode 14.0+
- **架构模式**：MVVM + Combine

### 项目结构

```
LitReader/
├── Models/                 # 数据模型
│   └── Book.swift         # 图书数据模型
├── Services/              # 业务服务层
│   ├── AIService.swift    # AI功能服务
│   ├── DataManager.swift  # 数据管理
│   ├── ReadingEngine.swift# 阅读引擎
│   ├── BookParser.swift   # 文件解析
│   ├── ThemeManager.swift # 主题管理
│   ├── SearchService.swift# 搜索服务
│   └── ...
├── Views/                 # 视图界面
│   ├── LibraryView.swift  # 图书馆界面
│   ├── ReaderView.swift   # 阅读界面
│   ├── SettingsView.swift # 设置界面
│   └── ...
└── Assets.xcassets/       # 资源文件
```

### 核心架构设计

1. **数据层（Models）**
   - `Book`：图书数据模型，包含元数据、阅读进度等
   - `BookFormat`：支持的文件格式枚举
   - `ReadingSession`：阅读会话记录

2. **服务层（Services）**
   - `DataManager`：统一的数据管理服务
   - `AIService`：AI功能集成服务
   - `ReadingEngine`：核心阅读引擎
   - `BookParser`：多格式文件解析
   - `ThemeManager`：主题和样式管理

3. **视图层（Views）**
   - 基于SwiftUI的响应式界面
   - 组件化设计，易于维护和扩展
   - 支持自适应布局和深色模式

## 🚀 快速开始

### 环境要求
- macOS 13.0+
- Xcode 14.0+
- iOS 15.0+ 设备或模拟器

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/yourusername/LitReader.git
cd LitReader
```

2. **打开项目**
```bash
open LitReader.xcodeproj
```

3. **配置开发者账号**
   - 在Xcode中选择你的开发者团队
   - 配置Bundle Identifier

4. **运行项目**
   - 选择目标设备或模拟器
   - 点击运行按钮或使用 `Cmd+R`

### 使用指南

1. **导入图书**
   - 将TXT、EPUB或PDF文件拖拽到应用中
   - 或使用文件选择器导入

2. **开始阅读**
   - 在图书馆中选择要阅读的书籍
   - 享受流畅的阅读体验

3. **使用AI功能**
   - 在阅读界面访问AI分析功能
   - 查看智能摘要和洞察

## 📋 开发路线图

### v1.0 - 基础功能 ✅
- [x] 基础阅读功能
- [x] 多格式文件支持
- [x] 主题系统
- [x] 书签和进度管理

### v1.1 - AI增强 🚧
- [x] AI智能摘要
- [x] 情感分析
- [ ] 智能问答
- [ ] 内容推荐优化

### v1.2 - 云端功能 📋
- [ ] iCloud同步
- [ ] 跨设备数据同步
- [ ] 在线图书库
- [ ] 社区分享功能

### v2.0 - 高级功能 💭
- [ ] 语音朗读
- [ ] 手写笔记
- [ ] AR阅读模式
- [ ] 多语言支持


### 如何贡献

1. **Fork 项目**
2. **创建功能分支** (`git checkout -b feature/AmazingFeature`)
3. **提交更改** (`git commit -m 'Add some AmazingFeature'`)
4. **推送到分支** (`git push origin feature/AmazingFeature`)
5. **创建 Pull Request**

### 开发规范

- 遵循Swift官方编码规范
- 使用SwiftUI最佳实践
- 添加适当的注释和文档
- 确保代码通过所有测试