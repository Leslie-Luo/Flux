# Plan Log - CLIProxyAPI Manager - macOS 菜单栏管理应用

## Initial Plan
- Created: 2026-01-05
- Objective: 交付一个 macOS 15+ 的 SwiftUI 菜单栏原生应用，作为 CLIProxyAPI 的图形化管理前端与监控仪表盘，采用类似 ClashMac 的现代化 UI 风格
- Total steps: 6

---

## S1.1: 创建 Xcode 项目与 MVVM 目录结构 - DONE
- Completed: 2026-01-05 13:41
- Changes: Sources/App/FluxApp.swift, Sources/Views/ContentView.swift, Flux.xcodeproj/project.pbxproj, .gitignore
- Verification: xcodebuild build succeeded, MVVM directory structure created, switched to Xcode native management

## S1.2 完成

- 添加 MenuBarExtra 菜单栏入口 (bolt.horizontal.circle 图标)
- 实现 Window(id: main) 单实例窗口
- 创建 AppViewModel 占位
- 菜单项: 打开面板 / 退出
- xcodebuild build 成功

## S1.3 完成

- 创建 SidebarItem 枚举（5 项导航）
- 创建 NavigationViewModel 管理 selection
- 实现 NavigationSplitView 左侧导航 + 右侧占位视图
- xcodebuild build 成功

## S1 完成

菜单栏应用骨架与导航框架已完成：
- Xcode 项目 + MVVM 目录结构
- MenuBarExtra 菜单栏入口
- Window(id:) 单实例窗口
- NavigationSplitView 左侧导航框架

## S2 完成

- 创建 CLIProxyAPIDiscoveryService (actor 后台执行)
- 实现路径探测：UserDefaults -> which -> 常见路径
- 创建 AppSettings 持久化配置
- 创建 SettingsView 设置页 UI
- 状态显示：已找到/未找到 + 版本信息
- 操作按钮：重新探测/选择本地/下载链接
- xcodebuild build 成功

## S3 完成

- 扩展 AppSettings: 添加 port, configPath 配置
- 创建 CLIProxyAPIRuntimeService (App 级生命周期)
- Process 生命周期管理: start/stop/restart
- 状态机: stopped/starting/running/stopping/failed
- SettingsView 运行控制 UI: 端口/配置/启动停止
- 日志捕获通过 Pipe handlers
- SIGKILL 兜底确保进程终止
- xcodebuild build 成功

## S4 拆分

将 S4 拆分为 3 个子步骤：
- S4.1: Health 检查与基础 ManagementClient
- S4.2: 账号列表与删除（GET/DELETE + UI）
- S4.3: 策略读取与更新 + 添加账号

## S4 完成

- 扩展 AppSettings: 添加 managementPort 配置
- 创建 ManagementAPIModels: HealthResponse, AccountDTO, StrategyDTO
- 创建 ManagementAPIClient (actor): health/accounts/strategies CRUD
- 创建 ManagementViewModel: 状态管理 + 异步操作
- 创建 ProvidersView: 连接状态 + 端口配置
- ContentView 路由 Provider 到 ProvidersView
- xcodebuild build 成功
