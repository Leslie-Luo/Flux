# Task: 更新 CLIProxyAPI GitHub 源地址

## Context
- Repo: Swift/SwiftUI macOS App
- Key files: Sources/Services/Proxy/CLIProxyAPIReleaseService.swift, Sources/Views/SettingsView.swift
- Background: CLIProxyAPI 项目已迁移到新的 GitHub 仓库 router-for-me/CLIProxyAPI

## Objective
- Goal: 将 CLIProxyAPI 的 GitHub 源地址抽象为 CLIProxyAPIReleaseSource 类型，实现单一来源管理，并更新为 router-for-me/CLIProxyAPI
- Non-goals: 不修改下载流程核心逻辑；不添加用户可配置 UI

## Constraints
- 仅修改仓库地址相关常量
- 不改动 UI 布局或交互逻辑

## Steps
- [>] S1: 创建 CLIProxyAPIReleaseSource.swift 定义发布源抽象类型
- [ ] S2: 更新 CLIProxyAPIReleaseService.swift 使用 ReleaseSource
- [ ] S3: 更新 SettingsView.swift 使用统一的 ReleaseSource
- [ ] S4: 构建验证

## Done
- CLIProxyAPIReleaseSource 类型已创建并包含 official 常量
- CLIProxyAPIReleaseService 和 SettingsView 共用同一 source
- Sources/ 目录下无 anthropics/claude-code-proxy 引用
- 项目可成功构建
