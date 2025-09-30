import SwiftUI
import UIKit

struct SettingsView: View {
    // MARK: - Constants
    private let githubUrl = "https://baidu.com/"
    
    // MARK: - State Properties
    @State private var currentIcon = UIApplication.shared.alternateIconName
    @StateObject private var optionsManager = OptionsManager.shared
    @State private var showingFeedback = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                feedbackSection
                
                appearanceSection
                
                advancedFeaturesSection
                
                resetSection
                
                aboutSection
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showingFeedback) {
                FeedbackView()
            }
        }
    }
}

// MARK: - Section Views
extension SettingsView {
    
    private var feedbackSection: some View {
        Section {
            Button(action: {
                showingFeedback = true
            }) {
                Label("反馈与支持", systemImage: "bubble.left.and.bubble.right")
            }
            .foregroundColor(.primary)
        } footer: {
            Text("遇到问题或有建议？告诉我们！")
        }
    }
    
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
            
            Link(destination: URL(string: githubUrl)!) {
                Label("GitHub 仓库", systemImage: "link")
            }
            .foregroundColor(.primary)
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

// MARK: - Supporting Views
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("主题", text: .constant(""))
                    TextEditor(text: .constant(""))
                        .frame(height: 150)
                } header: {
                    Text("反馈内容")
                }
                
                Section {
                    Button("提交反馈") {
                        // 提交反馈逻辑
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("反馈与支持")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
