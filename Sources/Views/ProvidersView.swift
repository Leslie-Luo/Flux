import SwiftUI

struct ProvidersView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var runtimeService: CLIProxyAPIRuntimeService
    @StateObject private var viewModel = ManagementViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Provider 管理")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Connection Status
                GroupBox("连接状态") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            connectionStatusIcon
                            connectionStatusText
                            Spacer()
                            Button("刷新") {
                                Task {
                                    await viewModel.checkHealth(baseURL: appSettings.managementBaseURL, password: appSettings.managementPassword)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if case .loaded(let health) = viewModel.healthState {
                            Divider()
                            HStack {
                                if let version = health.version {
                                    Text("版本: \(version)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let uptime = health.uptime {
                                    Text("运行时间: \(formatUptime(uptime))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Management Port Config
                GroupBox("Management API") {
                    HStack {
                        Text("端口:")
                        TextField(
                            "8081",
                            value: Binding(
                                get: { appSettings.managementPort },
                                set: { appSettings.managementPort = $0 }
                            ),
                            format: .number
                        )
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        
                        Text("(\(appSettings.managementBaseURL.absoluteString))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // Placeholder for accounts (S4.2)
                GroupBox("账号列表") {
                    Text("账号管理功能即将上线")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            await viewModel.checkHealth(baseURL: appSettings.managementBaseURL, password: appSettings.managementPassword)
        }
    }
    
    @ViewBuilder
    private var connectionStatusIcon: some View {
        switch viewModel.healthState {
        case .idle, .loading:
            ProgressView()
                .scaleEffect(0.7)
        case .loaded(let health) where health.status == "ok":
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .loaded:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
        case .error:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
    
    @ViewBuilder
    private var connectionStatusText: some View {
        switch viewModel.healthState {
        case .idle:
            Text("未检测")
                .foregroundStyle(.secondary)
        case .loading:
            Text("正在连接...")
                .foregroundStyle(.secondary)
        case .loaded(let health):
            Text(health.status == "ok" ? "已连接" : health.status)
                .foregroundStyle(health.status == "ok" ? .green : .orange)
        case .error(let message):
            VStack(alignment: .leading) {
                Text("连接失败")
                    .foregroundStyle(.red)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func formatUptime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    ProvidersView()
        .environmentObject(AppSettings())
        .environmentObject(CLIProxyAPIRuntimeService())
}

