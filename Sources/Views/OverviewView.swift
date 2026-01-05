import SwiftUI
import Charts

struct OverviewView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var runtimeService: CLIProxyAPIRuntimeService
    @StateObject private var viewModel = OverviewViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("概览")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Status Cards Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // Running Status Card
                    StatusCard(
                        title: "运行状态",
                        icon: runtimeService.state.isRunning ? "play.circle.fill" : "stop.circle",
                        iconColor: runtimeService.state.isRunning ? .green : .secondary
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(runtimeService.state.isRunning ? "运行中" : "已停止")
                                .font(.headline)
                                .foregroundStyle(runtimeService.state.isRunning ? .green : .secondary)
                            
                            if case .running(let pid, let port, let startDate) = runtimeService.state {
                                Text("PID: \(pid) | 端口: \(port)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("运行时长: \(formatUptime(from: startDate))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Health Status Card
                    StatusCard(
                        title: "连接状态",
                        icon: healthIcon,
                        iconColor: healthColor
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            switch viewModel.healthState {
                            case .idle:
                                Text("未检测")
                                    .foregroundStyle(.secondary)
                            case .loading:
                                HStack {
                                    ProgressView().scaleEffect(0.6)
                                    Text("检测中...")
                                }
                                .foregroundStyle(.secondary)
                            case .loaded(let health):
                                Text(health.status == "ok" ? "已连接" : health.status)
                                    .font(.headline)
                                    .foregroundStyle(health.status == "ok" ? .green : .orange)
                                if let version = health.version {
                                    Text("版本: \(version)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            case .error(let msg):
                                Text("连接失败")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                                Text(msg)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    
                    // Provider Count Card
                    StatusCard(
                        title: "API Keys",
                        icon: "key.horizontal",
                        iconColor: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            if case .loaded(let keys) = viewModel.apiKeysState {
                                Text("\(keys.count)")
                                    .font(.system(size: 32, weight: .bold))
                                Text("个 API Key 已配置")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("--")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Quick Actions Card
                    StatusCard(
                        title: "快捷操作",
                        icon: "bolt.horizontal",
                        iconColor: .orange
                    ) {
                        HStack(spacing: 12) {
                            if runtimeService.state.isRunning {
                                Button("停止") {
                                    Task { await runtimeService.stop() }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                
                                Button("重启") {
                                    Task {
                                        if let path = appSettings.effectiveCLIProxyAPIBinaryPath {
                                            await runtimeService.restart(
                                                binaryPath: path,
                                                port: appSettings.cliProxyAPIPort,
                                                configPath: appSettings.cliProxyAPIConfigPath
                                            )
                                        }
                                    }
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Button("启动") {
                                    Task {
                                        if let path = appSettings.effectiveCLIProxyAPIBinaryPath {
                                            await runtimeService.start(
                                                binaryPath: path,
                                                port: appSettings.cliProxyAPIPort,
                                                configPath: appSettings.cliProxyAPIConfigPath
                                            )
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(appSettings.effectiveCLIProxyAPIBinaryPath == nil)
                            }
                        }
                    }
                }
                
                // Port Info
                GroupBox("端口配置") {
                    HStack(spacing: 24) {
                        VStack(alignment: .leading) {
                            Text("代理端口")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(appSettings.cliProxyAPIPort)")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack(alignment: .leading) {
                            Text("管理端口")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(appSettings.managementPort)")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        Button("刷新") {
                            Task {
                                await viewModel.refresh(baseURL: appSettings.managementBaseURL, password: appSettings.managementPassword)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            await viewModel.refresh(baseURL: appSettings.managementBaseURL, password: appSettings.managementPassword)
        }
    }
    
    private var healthIcon: String {
        switch viewModel.healthState {
        case .loaded(let h) where h.status == "ok": return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        default: return "questionmark.circle"
        }
    }
    
    private var healthColor: Color {
        switch viewModel.healthState {
        case .loaded(let h) where h.status == "ok": return .green
        case .error: return .red
        default: return .secondary
        }
    }
    
    private func formatUptime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct StatusCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(iconColor)
                    Text(title)
                        .font(.headline)
                    Spacer()
                }
                
                content
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    OverviewView()
        .environmentObject(AppSettings())
        .environmentObject(CLIProxyAPIRuntimeService())
}
