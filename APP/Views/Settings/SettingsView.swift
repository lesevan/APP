import SwiftUI
import UIKit

struct SettingsView: View {
    // MARK: - State Properties
    @State private var currentIcon = UIApplication.shared.alternateIconName
    @StateObject private var optionsManager = OptionsManager.shared
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                appearanceSection
                
                advancedFeaturesSection
                
                resetSection
                
                aboutSection
            }
            .navigationTitle("设置")
        }
    }
}

// MARK: - Section Views
extension SettingsView {
    
    private var appearanceSection: some View {
        Section(header: Text("外观")) {
            NavigationLink(destination: AppearanceView().environmentObject(ThemeManager.shared)) {
                Label("主题与外观", systemImage: "paintbrush")
            }
            
            NavigationLink(destination: AppIconView(currentIcon: $currentIcon)) {
                HStack {
                    Label("应用图标", systemImage: "app.badge")
                    Spacer()
                    if let currentIcon = currentIcon {
                        Text(currentIcon.replacingOccurrences(of: "AppIcon-", with: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("默认")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var advancedFeaturesSection: some View {
        Section {
            NavigationLink(destination: CertificatesView()) {
                Label("证书管理", systemImage: "checkmark.seal")
            }
            
            NavigationLink(destination: ConfigurationView()) {
                Label("签名配置", systemImage: "signature")
            }
            
            NavigationLink(destination: ArchiveView()) {
                Label("归档设置", systemImage: "archivebox")
            }
            
            NavigationLink(destination: InstallationView()) {
                Label("安装选项", systemImage: "arrow.down.circle")
            }
        } header: {
            Text("高级功能")
        } footer: {
            Text("管理证书、配置签名选项和安装设置。")
        }
    }

    private var resetSection: some View {
        Section {
            NavigationLink(destination: ResetView()) {
                Label("重置应用", systemImage: "trash")
                    .foregroundColor(.red)
            }
        } footer: {
            Text("重置应用的源、证书、应用程序和设置。此操作不可撤销。")
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("关于")) {
            HStack {
                Label("版本", systemImage: "info.circle")
                Spacer()
                Text(appVersion)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Computed Properties
extension SettingsView {
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
