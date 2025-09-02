//
//  Created by pxx917144686 on 2025/08/20.
//
import SwiftUI
// 状态栏样式管理器
class StatusBarManager: ObservableObject {
    static let shared = StatusBarManager()
    @Published var isDarkMode: Bool = false
    private init() {
        // 监听主题变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeChanged),
            name: Notification.Name("ThemeChanged"),
            object: nil
        )
        // 初始化状态
        updateStatusBarStyle()
    }
    @objc private func themeChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updateStatusBarStyle()
        }
    }
    private func updateStatusBarStyle() {
        isDarkMode = ThemeManager.shared.selectedTheme == .dark
    }
}
// 导入主题管理器
struct APPMain: App {
    @StateObject private var statusBarManager = StatusBarManager.shared
    init() {
        AppConfiguration.shared.initialize()
        // 确保应用启动时使用浅色模式作为默认设置
        // 只有设置过深色模式时才使用深色模式
        if UserDefaults.standard.string(forKey: "SelectedTheme") == nil {
            ThemeManager.shared.resetToDefaultTheme()
        }
    }
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(ThemeManager.shared)
                .preferredColorScheme(getPreferredColorScheme())
                .onReceive(statusBarManager.$isDarkMode) { isDark in
                    // 强制更新状态栏样式
                    setStatusBarStyle(isDark: isDark)
                }
        }
    }
    // 根据主题管理器返回对应的颜色方案
    private func getPreferredColorScheme() -> ColorScheme? {
        switch ThemeManager.shared.selectedTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    // 设置状态栏样式
    private func setStatusBarStyle(isDark: Bool) {
        // 使用UIApplication来设置状态栏样式
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }
}
// Traditional main function
APPMain.main()
