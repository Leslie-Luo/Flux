# Flux - CLIProxyAPI macOS 管理应用

## 项目概述

Flux 是一个 macOS 原生菜单栏应用，用于管理 CLIProxyAPI 代理服务。采用 SwiftUI + MVVM 架构，支持 macOS 15.0+。

## 技术栈

- **语言**: Swift 6.0
- **框架**: SwiftUI
- **架构**: MVVM
- **项目管理**: xcodegen (project.yml)
- **最低版本**: macOS 15.0 (Sequoia)

## 项目结构

```
Sources/
├── App/
│   └── FluxApp.swift              # 主入口，MenuBarExtra + Window
├── Models/
│   ├── SidebarItem.swift          # 侧边栏导航项枚举
│   └── ManagementAPIModels.swift  # API 数据模型
├── ViewModels/
│   ├── AppViewModel.swift
│   ├── NavigationViewModel.swift
│   ├── ManagementViewModel.swift
│   └── OverviewViewModel.swift
├── Views/
│   ├── ContentView.swift          # 主 NavigationSplitView
│   ├── OverviewView.swift         # 概览仪表盘
│   ├── ProvidersView.swift        # Provider 管理
│   ├── SettingsView.swift         # 设置页
│   ├── LogsView.swift             # 日志查看
│   └── PlaceholderView.swift
├── Services/
│   ├── AppSettings.swift          # UserDefaults + Keychain 持久化
│   ├── CLIProxyAPIDiscoveryService.swift  # 自动发现/下载
│   ├── CLIProxyAPIRuntimeService.swift    # 进程生命周期管理
│   ├── ManagementAPIClient.swift          # REST API 客户端 (actor)
│   ├── NotificationService.swift          # 系统通知
│   └── UpdateService.swift                # 自动更新占位
└── Resources/
    ├── en.lproj/Localizable.strings
    └── zh-Hans.lproj/Localizable.strings
```

## CLIProxyAPI 连接

### API 端点
- **Base URL**: `http://127.0.0.1:8317/v0/management`
- **认证**: `Authorization: Bearer <management-key>`
- **健康检查**: `GET /config`
- **API Keys**: `GET/PUT/DELETE /api-keys`

### 默认配置
- **端口**: 8317 (代理和管理共用)
- **密码**: 存储在 macOS Keychain

## 开发指南

### 构建项目
```bash
# 生成 Xcode 项目
xcodegen generate

# 构建
xcodebuild build -scheme Flux -configuration Debug CODE_SIGNING_ALLOWED=NO

# 运行
open /Users/leslie/Library/Developer/Xcode/DerivedData/Flux-*/Build/Products/Debug/Flux.app
```

### 添加新文件后
必须重新运行 `xcodegen generate` 以更新 Xcode 项目。

### 关键服务

1. **CLIProxyAPIRuntimeService** - 进程管理
   - 状态机: `stopped → starting → running → stopping → stopped`
   - 支持 SIGTERM + SIGKILL 优雅关闭
   - stdout/stderr 日志收集

2. **ManagementAPIClient** - API 客户端 (actor)
   - 线程安全的 async/await API
   - 自动处理 401 认证错误

3. **AppSettings** - 配置持久化
   - UserDefaults: 端口、路径
   - Keychain: 管理密码

## 代码规范

- 使用 `@MainActor` 标记 UI 相关类
- 使用 `actor` 处理并发 API 调用
- ViewModel 使用 `@Published` 属性
- View 使用 `@EnvironmentObject` 共享状态

## 待实现功能

- [ ] 内置 CLIProxyAPI 二进制 (Bundled mode)
- [ ] 本地/内置模式切换
- [ ] 从配置文件自动读取端口
- [ ] Sparkle 自动更新集成
