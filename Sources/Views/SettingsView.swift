import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var runtimeService: CLIProxyAPIRuntimeService
    @StateObject private var coordinator = ManagedProxyCoordinator()
    @State private var showingConfigPicker = false
    @State private var portString = ""

    private var downloadURL: URL { CLIProxyAPIReleaseSource.official.releasesPageURL }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("设置")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                managedModeSection
                
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
                                        if let path = ProxyStorageManager.shared.currentBinaryPath?.path {
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
                                        if let path = ProxyStorageManager.shared.currentBinaryPath?.path {
                                            await runtimeService.start(
                                                binaryPath: path,
                                                port: appSettings.cliProxyAPIPort,
                                                configPath: appSettings.cliProxyAPIConfigPath
                                            )
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(ProxyStorageManager.shared.currentBinaryPath == nil)
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

            await coordinator.refresh()
            await coordinator.checkForUpdate()
        }
    }

    @ViewBuilder
    private var managedModeSection: some View {
        GroupBox("托管模式") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("当前版本")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(coordinator.currentVersion.map { "v\($0)" } ?? "未安装")
                            .font(.headline)
                    }

                    Spacer()

                    Button("检查更新") {
                        Task { await coordinator.checkForUpdate() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(coordinator.isCheckingUpdate || coordinator.isInstalling)
                }

                if coordinator.isCheckingUpdate {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                if let latest = coordinator.availableLatest {
                    Divider()

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("最新版本")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("v\(latest.versionNumber)")
                                .font(.headline)
                        }

                        Spacer()

                        let isUpdateAvailable = latest.versionNumber != coordinator.currentVersion
                        if isUpdateAvailable {
                            Button(coordinator.currentVersion == nil ? "安装" : "更新") {
                                Task { await installAndMaybeRestart(release: latest) }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(coordinator.isInstalling)
                        } else {
                            Text("已是最新")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if coordinator.isInstalling, let progress = coordinator.downloadProgress {
                    ProgressView(value: progress.fractionCompleted)
                    Text(progress.formattedProgress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let message = coordinator.error, !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Divider()

                if coordinator.installedVersions.isEmpty {
                    Text("暂无已安装版本")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(coordinator.installedVersions) { version in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("v\(version.version)")
                                        .font(.headline)
                                    if let date = version.releaseDate {
                                        Text(date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if version.version == coordinator.currentVersion {
                                    Text("当前")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Button("启用") {
                                        Task { await activateAndMaybeRestart(version: version.version) }
                                    }
                                    .buttonStyle(.bordered)

                                    Button("删除") {
                                        Task { await coordinator.delete(version: version.version) }
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                }
                            }
                        }
                    }
                }

                Divider()

                Link("查看 Release 页面", destination: downloadURL)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
    }

    private func activateAndMaybeRestart(version: String) async {
        let wasRunning = runtimeService.state.isRunning
        if wasRunning {
            await runtimeService.stop()
        }

        await coordinator.activate(version: version)

        guard wasRunning, let path = ProxyStorageManager.shared.currentBinaryPath?.path else { return }
        await runtimeService.start(
            binaryPath: path,
            port: appSettings.cliProxyAPIPort,
            configPath: appSettings.cliProxyAPIConfigPath
        )
    }

    private func installAndMaybeRestart(release: GitHubRelease) async {
        let wasRunning = runtimeService.state.isRunning
        if wasRunning {
            await runtimeService.stop()
        }

        await coordinator.install(release: release)

        guard wasRunning, let path = ProxyStorageManager.shared.currentBinaryPath?.path else { return }
        await runtimeService.start(
            binaryPath: path,
            port: appSettings.cliProxyAPIPort,
            configPath: appSettings.cliProxyAPIConfigPath
        )
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
