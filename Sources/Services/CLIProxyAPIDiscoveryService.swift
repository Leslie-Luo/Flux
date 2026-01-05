import Foundation

enum CLIProxyAPIStatus: Equatable {
    case unknown
    case notFound
    case found(path: String, version: String?)
}

actor CLIProxyAPIDiscoveryActor {
    private let commonPaths = [
        "~/.CLIProxyAPI/bin/CLIProxyAPI",
        "/usr/local/bin/CLIProxyAPI",
        "/opt/homebrew/bin/CLIProxyAPI",
        "~/go/bin/CLIProxyAPI"
    ]
    
    func discover(customPath: String? = nil) async -> (status: CLIProxyAPIStatus, path: String?) {
        // Check custom path first
        if let custom = customPath {
            let expanded = NSString(string: custom).expandingTildeInPath
            if FileManager.default.isExecutableFile(atPath: expanded) {
                let version = getVersion(at: expanded)
                return (.found(path: expanded, version: version), expanded)
            }
        }
        
        // Try which command
        if let whichPath = runWhich() {
            let version = getVersion(at: whichPath)
            return (.found(path: whichPath, version: version), whichPath)
        }
        
        // Check common paths
        for path in commonPaths {
            let expanded = NSString(string: path).expandingTildeInPath
            if FileManager.default.isExecutableFile(atPath: expanded) {
                let version = getVersion(at: expanded)
                return (.found(path: expanded, version: version), expanded)
            }
        }
        
        return (.notFound, nil)
    }
    
    private func runWhich() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["CLIProxyAPI"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    return output
                }
            }
        } catch {}
        
        return nil
    }
    
    private func getVersion(at path: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["--version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    return output
                }
            }
        } catch {}
        
        return nil
    }
}

@MainActor
final class CLIProxyAPIDiscoveryService: ObservableObject {
    @Published private(set) var status: CLIProxyAPIStatus = .unknown
    
    private let actor = CLIProxyAPIDiscoveryActor()
    
    func discover(customPath: String? = nil, persistTo settings: AppSettings? = nil) async {
        let result = await actor.discover(customPath: customPath)
        status = result.status
        
        // Persist discovered path
        if let path = result.path {
            settings?.cliProxyAPIPath = path
        }
    }
}
