# Task: CLIProxyAPI Manager - macOS 菜单栏管理应用

## Context
- Repo: Swift/SwiftUI macOS App
- Key files: Quotio 参考项目 (nguyenphutrong/quotio), ClashMac 概览页设计风格
- Background: 创建类似 Quotio 功能的 macOS 应用，用于管理 AI 编程助手的本地代理服务器，账号管理完全通过 CLIProxyAPI 实现

## Objective
- Goal: 交付一个 macOS 15+ 的 SwiftUI 菜单栏原生应用，作为 CLIProxyAPI 的图形化管理前端与监控仪表盘，采用类似 ClashMac 的现代化 UI 风格
- Non-goals: 不在 App 内存储 Provider 凭据；不实现代理核心能力；不做跨平台；不追求 1:1 复刻

## Constraints
- macOS 15.0+ (Sequoia)
- SwiftUI + MVVM 架构
- 账号管理通过 CLIProxyAPI Management API
- CLIProxyAPI 支持复用本地或引导下载

## Steps
- [x] S1: 菜单栏应用骨架与导航框架（MVVM + 左侧导航）
- [x] S2: CLIProxyAPI 发现与获取（复用本地/引导下载）
- [x] S3: CLIProxyAPI 进程与端口/配置管理
- [x] S4: Management API 客户端（账号/策略/健康检查）
- [>] S5: 概览页与实时监控仪表盘（状态/流量/Token/配额卡片）
- [ ] S6: 系统集成与发布准备（通知、多语言、Sparkle、签名公证）

## Substeps (if expanded)
- [x] S1.1: 创建 Xcode 项目与 MVVM 目录结构
- [x] S1.2: 实现菜单栏入口与窗口管理（MenuBarExtra + 单实例窗口）
- [x] S1.3: 创建 NavigationSplitView 导航框架与占位视图
- [x] S4.1: Health 检查与基础 ManagementClient
- [x] S4.2: 账号列表与删除（GET/DELETE + UI）
- [x] S4.3: 策略读取与更新 + 添加账号

## Done
- 可通过 CLIProxyAPI Management API 管理账号，App 不存储 Provider 凭据
- 支持检测本地 CLIProxyAPI 并复用或引导下载，进程可一键启停
- 概览页展示运行状态/流量/Token/配额，异常时推送通知，支持中英文与 Sparkle 更新
