import SwiftUI
import UIKit
import Darwin

struct SettingsView: View {
    private let _githubUrl = "https://github.com/pxx917144686/APP"
    @State private var currentIcon = UIApplication.shared.alternateIconName
    @StateObject private var optionsManager = OptionsManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                _feedback()
                
                appearanceSection
                
                advancedFeaturesSection
                
                resetSection
            }
        }
    }
}

extension SettingsView {
    @ViewBuilder
    private func _feedback() -> some View {
        Section {
            Button("提交反馈", systemImage: "safari") {
                if let url = URL(string: "\(_githubUrl)/issues") {
                    UIApplication.shared.open(url)
                }
            }
            Button("👉看看源代码", systemImage: "safari") {
                if let url = URL(string: _githubUrl) {
                    UIApplication.shared.open(url)
                }
            }
        } footer: {
            Text("有任何问题，或建议，请随时提交。")
        }
    }

    private var appearanceSection: some View {
        Section {
            NavigationLink(destination: AppearanceView().environmentObject(ThemeManager.shared)) {
                Label("外观", systemImage: "paintbrush")
            }
            NavigationLink(destination: AppIconView(currentIcon: $currentIcon)) {
                Label("图标", systemImage: "app.badge")
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
                Label("重置", systemImage: "trash")
            }
        } footer: {
            Text("重置应用的源、证书、应用程序和设置。")
        }
    }    

}
