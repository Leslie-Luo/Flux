import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var runtimeService: CLIProxyAPIRuntimeService
    @StateObject private var discoveryService = CLIProxyAPIDiscoveryService()
    @State private var showingFilePicker = false
    @State private var showingConfigPicker = false
    @State private var portString = ""

    private let downloadURL = URL(string: "https://github.com/anthropics/claude-code-proxy/releases")!
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("设置")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // CLIProxyAPI Discovery
                GroupBox("CLIProxyAPI 路径") {
                    VStack(alignment: .leading, spacing: 12) {
                        statusRow
                        
                        Divider()
                        
                        HStack(spacing: 12) {
                            Button("重新探测") {
                                Task {
                                    await discoveryService.discover(
                                        customPath: appSettings.cliProxyAPIPath,
                                        persistTo: appSettings
                                    )
                                }
                            }
                            
                            Button("选择本地二进制...") {
                                showingFilePicker = true
                            }
                            
                            Link("下载 CLIProxyAPI", destination: downloadURL)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                }
                
                // CLIProxyAPI Runtime Control
                GroupBox("运行控制") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Port configuration (single port for CLIProxyAPI)
                        HStack {
                            Text("端口:")
                            TextField("8317", text: $portString)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: portString) { _, newValue in
                                    if let port = Int(newValue), port > 0, port <= 65535 {
                                        appSettings.cliProxyAPIPort = port
                                        appSettings.managementPort = port // Same port
                                    }
                                }

                            Text("(默认 8317)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()
                        }

                        Divider()

                        // Password configuration
                        HStack {
                            Text("管理密码:")
                            SecureField("输入密码", text: $appSettings.managementPassword)
                                .frame(width: 200)
                                .textFieldStyle(.roundedBorder)

                            Text("用于连接 CLIProxyAPI")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()
                        }

                        Divider()

                        // Config file
                        HStack {
                            if let configPath = appSettings.cliProxyAPIConfigPath {
                                Text("配置: \(URL(fileURLWithPath: configPath).lastPathComponent)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Button("选择配置...") {
                                showingConfigPicker = true
                            }
                            .buttonStyle(.bordered)

                            Spacer()
                        }

                        Divider()
                        
                        // Runtime status
                        runtimeStatusRow
                        
                        Divider()
                        
                        // Control buttons
                        HStack(spacing: 12) {
                            if runtimeService.state.isRunning {
                                Button("停止") {
                                    Task { await runtimeService.stop() }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                
                                Button("重启") {
                                    Task {
                                        if let path = appSettings.cliProxyAPIPath {
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
                                        if let path = appSettings.cliProxyAPIPath {
                                            await runtimeService.start(
                                                binaryPath: path,
                                                port: appSettings.cliProxyAPIPort,
                                                configPath: appSettings.cliProxyAPIConfigPath
                                            )
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(appSettings.cliProxyAPIPath == nil)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.unixExecutable, .item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                appSettings.cliProxyAPIPath = url.path
                Task {
                    await discoveryService.discover(
                        customPath: url.path,
                        persistTo: appSettings
                    )
                }
            }
        }
        .fileImporter(
            isPresented: $showingConfigPicker,
            allowedContentTypes: [.yaml, .json, .item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                appSettings.cliProxyAPIConfigPath = url.path
            }
        }
        .task {
            portString = String(appSettings.cliProxyAPIPort)
            await discoveryService.discover(
                customPath: appSettings.cliProxyAPIPath,
                persistTo: appSettings
            )
        }
    }
    
    @ViewBuilder
    private var statusRow: some View {
        HStack {
            switch discoveryService.status {
            case .unknown:
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.secondary)
                Text("正在检测...")
                    .foregroundStyle(.secondary)
                
            case .notFound:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text("未找到 CLIProxyAPI")
                    .foregroundStyle(.secondary)
                
            case .found(let path, let version):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                VStack(alignment: .leading) {
                    Text("已找到 CLIProxyAPI")
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let version = version {
                        Text("版本: \(version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var runtimeStatusRow: some View {
        HStack {
            switch runtimeService.state {
            case .stopped:
                Image(systemName: "stop.circle")
                    .foregroundStyle(.secondary)
                Text("已停止")
                    .foregroundStyle(.secondary)
                
            case .starting:
                ProgressView()
                    .scaleEffect(0.7)
                Text("正在启动...")
                    .foregroundStyle(.secondary)
                
            case .running(let pid, let port, let startDate):
                Image(systemName: "play.circle.fill")
                    .foregroundStyle(.green)
                VStack(alignment: .leading) {
                    Text("运行中")
                        .foregroundStyle(.green)
                    Text("PID: \(pid) | 端口: \(port)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("启动时间: \(startDate.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
            case .stopping:
                ProgressView()
                    .scaleEffect(0.7)
                Text("正在停止...")
                    .foregroundStyle(.secondary)
                
            case .failed(let reason):
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                VStack(alignment: .leading) {
                    Text("启动失败")
                        .foregroundStyle(.red)
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
        .environmentObject(CLIProxyAPIRuntimeService())
}
