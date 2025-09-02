//
//  ThemeManager.swift
//  APP
//
//  Created by pxx917144686 on 2025/08/20.
//
import SwiftUI
import Foundation
/// 主题模式枚举
enum ThemeMode: String, CaseIterable {
    case light = "浅色"
    case dark = "深色"
    /// 主题对应的强调色
    var accentColor: Color {
        switch self {
        case .light:
            return Color.blue
        case .dark:
            return Color.cyan // 深色模式使用青色作为强调色，更现代
        }
    }
}
/// 高级现代深色UI颜色系统
struct ModernDarkColors {
    // 背景色系
    static let primaryBackground = Color(red: 0.05, green: 0.05, blue: 0.08) // 深蓝黑
    static let secondaryBackground = Color(red: 0.08, green: 0.08, blue: 0.12) // 稍亮的深蓝黑
    static let tertiaryBackground = Color(red: 0.12, green: 0.12, blue: 0.16) // 卡片背景
    // 表面色系
    static let surfacePrimary = Color(red: 0.15, green: 0.15, blue: 0.20) // 主要表面
    static let surfaceSecondary = Color(red: 0.20, green: 0.20, blue: 0.25) // 次要表面
    static let surfaceElevated = Color(red: 0.25, green: 0.25, blue: 0.30) // 提升表面
    // 文字色系
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.8, green: 0.8, blue: 0.85) // 次要文字
    static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.65) // 第三级文字
    // 强调色系
    static let accentPrimary = Color.cyan
    static let accentSecondary = Color(red: 0.0, green: 0.8, blue: 1.0) // 亮青色
    static let accentTertiary = Color(red: 0.2, green: 0.8, blue: 0.8) // 青绿色
    // 边框和分割线
    static let borderPrimary = Color(red: 0.3, green: 0.3, blue: 0.35)
    static let borderSecondary = Color(red: 0.2, green: 0.2, blue: 0.25)
    // 阴影
    static let shadowColor = Color.black.opacity(0.4)
}
/// 主题管理器 - 单例类，管理整个APP的主题设置
class ThemeManager: ObservableObject {
    /// 单例实例
    static let shared = ThemeManager()
    /// 当前选中的主题模式
    @Published var selectedTheme: ThemeMode = .light {
        didSet {
            // 当主题改变时应用新主题
            applyTheme(selectedTheme)
            // 保存主题设置到用户默认设置
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "SelectedTheme")
        }
    }
    /// 系统是否为深色模式（用于自动主题）
    @Published var isSystemDarkMode: Bool = false
    private init() {
        // 强制重置为浅色模式（临时修复）
        UserDefaults.standard.removeObject(forKey: "SelectedTheme")
        // 从用户默认设置加载保存的主题，如果没有保存过则默认为浅色模式
        if let savedTheme = UserDefaults.standard.string(forKey: "SelectedTheme"),
           let theme = ThemeMode(rawValue: savedTheme) {
            selectedTheme = theme
        } else {
            // 默认设置为浅色模式
            selectedTheme = .light
        }
        // 检测系统主题
        detectSystemTheme()
        // 初始应用主题
        applyTheme(selectedTheme)
    }
    /// 重置主题设置为默认浅色模式（用于首次登录）
    func resetToDefaultTheme() {
        selectedTheme = .light
        UserDefaults.standard.removeObject(forKey: "SelectedTheme")
    }
    /// 强制重置为浅色模式（临时修复深色模式问题）
    func forceResetToLightTheme() {
        selectedTheme = .light
        UserDefaults.standard.removeObject(forKey: "SelectedTheme")
        UserDefaults.standard.synchronize()
    }
    /// 检测系统主题
    private func detectSystemTheme() {
        // 使用ColorScheme环境值检测系统主题
        // 这里简化处理，实际应用中可以通过环境值获取
        isSystemDarkMode = false // 默认浅色，实际应该从环境获取
    }
    /// 应用指定的主题模式到整个APP
    /// - Parameter mode: 要应用的主题模式
    func applyTheme(_ mode: ThemeMode) {
        // 发送通知，通知其他组件主题已更改
        NotificationCenter.default.post(name: Notification.Name("ThemeChanged"), object: mode)
    }
    /// 获取当前主题的背景色
    var backgroundColor: Color {
        switch selectedTheme {
        case .light:
            return Color.white
        case .dark:
            return ModernDarkColors.primaryBackground
        }
    }
    /// 获取当前主题的卡片背景色
    var cardBackgroundColor: Color {
        switch selectedTheme {
        case .light:
            return Color.white
        case .dark:
            return ModernDarkColors.surfaceSecondary
        }
    }
    /// 获取当前主题的主要文字颜色
    var primaryTextColor: Color {
        switch selectedTheme {
        case .light:
            return Color.black
        case .dark:
            return ModernDarkColors.textPrimary
        }
    }
    /// 获取当前主题的次要文字颜色
    var secondaryTextColor: Color {
        switch selectedTheme {
        case .light:
            return Color.gray
        case .dark:
            return ModernDarkColors.textSecondary
        }
    }
    /// 获取当前主题的强调色
    var accentColor: Color {
        switch selectedTheme {
        case .light:
            return Color.blue
        case .dark:
            return ModernDarkColors.accentPrimary
        }
    }
    /// 更新系统主题状态（在SwiftUI环境中调用）
    func updateSystemTheme(isDark: Bool) {
        isSystemDarkMode = isDark
        // 不再需要跟随系统模式的处理
    }
}
/// 主题预览视图 - 显示主题效果的预览，与截图样式一致
struct ThemePreviewView: View {
    let mode: ThemeMode
    let isSelected: Bool
    var body: some View {
        // 浅色和深色模式显示单个预览图
        SingleThemePreview(mode: mode, isSelected: isSelected)
            .frame(width: 100, height: 120)
    }
}
/// 单个主题预览组件
struct SingleThemePreview: View {
    let mode: ThemeMode
    let isSelected: Bool
    var body: some View {
        ZStack {
            // 根据主题模式设置背景色
            mode == .light ? Color.white : Color(red: 0.12, green: 0.12, blue: 0.14)
            VStack {
                // 状态栏区域 - 简化
                HStack {
                    Spacer()
                    Text("9:41")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(mode == .light ? .black : .white)
                    Spacer()
                }
                .padding(.top, 8)
                // 标题栏
                HStack {
                    Text("设置")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(mode == .light ? .black : .white)
                    Spacer()
                }
                .padding(.horizontal, 12)
                // 内容区域
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(mode == .light ? Color(red: 0.9, green: 0.9, blue: 0.93) : Color(red: 0.25, green: 0.25, blue: 0.3))
                        .frame(height: 24)
                        .cornerRadius(12)
                    Rectangle()
                        .fill(mode == .light ? Color(red: 0.85, green: 0.85, blue: 0.9) : Color(red: 0.2, green: 0.2, blue: 0.25))
                        .frame(height: 24)
                        .cornerRadius(12)
                }
                .padding(.top, 12)
                Spacer()
            }
        }
        .frame(width: 50, height: 120)
        .cornerRadius(12)
        .shadow(radius: 2)
        // 选中时添加蓝色边框
        .border(isSelected ? Color.blue : Color.clear, width: 2)
    }
}
// 主题相关的环境键
struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}
// 环境扩展，方便访问主题管理器
extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}