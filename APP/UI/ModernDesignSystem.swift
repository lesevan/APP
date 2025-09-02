//
//  ModernDesignSystem.swift
//  APP
//  由 pxx917144686 UI 系统创建于 2025.08.19
//  统一设计 - 提供一致的 UI 组件和样式
//
import SwiftUI

// MARK: - 设计系统文档
/*
 此文件包含 APP 项目的统一设计系统。
 它提供：
 - 调色板（Microsoft Fluent + Google Material）
 - 排版系统
 - 间距和布局常量
 - 可重用 UI 组件
 - 动画预设
 使用方法：
 - 在任何 SwiftUI 视图中导入此文件
 - 使用预定义的颜色、字体和组件
 - 遵循既定的设计模式
*/

// MARK: - 颜色系统（Microsoft Fluent + Google Material）
extension Color {
    // Microsoft Fluent 颜色
    static let fluentBlue = Color(red: 0.04, green: 0.36, blue: 0.87)
    static let fluentPurple = Color(red: 0.41, green: 0.18, blue: 0.86)
    static let fluentTeal = Color(red: 0.0, green: 0.69, blue: 0.69)
    static let fluentOrange = Color(red: 1.0, green: 0.55, blue: 0.0)
    
    // Google Material 颜色
    static let materialBlue = Color(red: 0.12, green: 0.47, blue: 1.0)
    static let materialGreen = Color(red: 0.0, green: 0.76, blue: 0.35)
    static let materialRed = Color(red: 0.96, green: 0.26, blue: 0.21)
    static let materialAmber = Color(red: 1.0, green: 0.76, blue: 0.03)
    static let materialPurple = Color(red: 0.61, green: 0.15, blue: 0.69)
    static let materialPink = Color(red: 0.91, green: 0.12, blue: 0.39)
    static let materialTeal = Color(red: 0.0, green: 0.59, blue: 0.53)
    static let materialIndigo = Color(red: 0.25, green: 0.32, blue: 0.71)
    static let materialCyan = Color(red: 0.0, green: 0.74, blue: 0.83)
    static let materialOrange = Color(red: 1.0, green: 0.34, blue: 0.13)
    static let materialLightBlue = Color(red: 0.01, green: 0.66, blue: 0.96)
    static let materialBrown = Color(red: 0.47, green: 0.33, blue: 0.28)
    static let materialDeepPurple = Color(red: 0.40, green: 0.23, blue: 0.72)
    static let materialDeepOrange = Color(red: 1.0, green: 0.34, blue: 0.13)
    
    // 表面颜色 - 为简化使用自定义颜色
    static let surfacePrimary = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let surfaceSecondary = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let surfaceTertiary = Color(red: 0.93, green: 0.93, blue: 0.95)
    static let cardBackground = Color(red: 0.98, green: 0.98, blue: 1.0)
    
    // 强调色
    static let primaryAccent = fluentBlue
    static let secondaryAccent = materialGreen
    
    // 主题感知颜色
    static var themeAwarePrimaryAccent: Color {
        return ThemeManager.shared.accentColor
    }
    static var themeAwareBackground: Color {
        return ThemeManager.shared.backgroundColor
    }
    static var themeAwareCardBackground: Color {
        return ThemeManager.shared.cardBackgroundColor
    }
}

// MARK: - 排版系统
extension Font {
    // 展示型排版（大标题）
    static let displayLarge = Font.system(size: 57, weight: .regular, design: .rounded)
    static let displayMedium = Font.system(size: 45, weight: .regular, design: .rounded)
    static let displaySmall = Font.system(size: 36, weight: .regular, design: .rounded)
    
    // 标题型排版
    static let headlineLarge = Font.system(size: 32, weight: .medium, design: .rounded)
    static let headlineMedium = Font.system(size: 28, weight: .medium, design: .rounded)
    static let headlineSmall = Font.system(size: 24, weight: .medium, design: .rounded)
    
    // 小标题排版
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let titleMedium = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let titleSmall = Font.system(size: 14, weight: .semibold, design: .rounded)
    
    // 正文排版
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // 标签排版
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
}

// MARK: - 间距系统
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - 圆角系统
enum CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let round: CGFloat = 50
}

// MARK: - 阴影系统
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    static let subtle = ShadowStyle(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    static let soft = ShadowStyle(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 16, x: 0, y: 4)
    static let strong = ShadowStyle(color: .black.opacity(0.2), radius: 24, x: 0, y: 8)
}
// 提取卡片样式以避免泛型不匹配
enum ModernCardStyle {
    case elevated
    case outlined
    case filled
}
// MARK: - 现代卡片组件
struct ModernCard<Content: View>: View {
    let content: Content
    var style: ModernCardStyle = .elevated
    var padding: CGFloat = Spacing.md
    init(style: ModernCardStyle = .elevated, padding: CGFloat = Spacing.md, @ViewBuilder content: () -> Content) {
        self.style = style
        self.padding = padding
        self.content = content()
    }
    var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .modifier(CardStyleModifier(style: style))
    }
    private var cardBackground: some View {
        Group {
            switch style {
            case .elevated:
                Color.themeAwareCardBackground
            case .outlined:
                Color.themeAwareCardBackground
            case .filled:
                Color.themeAwareCardBackground
            }
        }
    }
}
struct CardStyleModifier: ViewModifier {
    let style: ModernCardStyle
    func body(content: Content) -> some View {
        switch style {
        case .elevated:
            content
                .shadow(color: ShadowStyle.medium.color, radius: ShadowStyle.medium.radius, x: ShadowStyle.medium.x, y: ShadowStyle.medium.y)
        case .outlined:
            content
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        case .filled:
            content
        }
    }
}
// MARK: - 现代按钮组件
struct ModernButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    var style: ButtonStyle = .primary
    var size: ButtonSize = .medium
    var isDisabled: Bool = false
    enum ButtonStyle {
        case primary
        case secondary
        case ghost
        case danger
    }
    enum ButtonSize {
        case small
        case medium
        case large
        var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: Spacing.xs, leading: Spacing.sm, bottom: Spacing.xs, trailing: Spacing.sm)
            case .medium: return EdgeInsets(top: Spacing.sm, leading: Spacing.md, bottom: Spacing.sm, trailing: Spacing.md)
            case .large: return EdgeInsets(top: Spacing.md, leading: Spacing.lg, bottom: Spacing.md, trailing: Spacing.lg)
            }
        }
    }
    init(style: ButtonStyle = .primary, size: ButtonSize = .medium, isDisabled: Bool = false, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.style = style
        self.size = size
        self.isDisabled = isDisabled
        self.action = action
        self.label = label()
    }
    var body: some View {
        Button(action: action) {
            label
                .font(labelFont)
                .foregroundColor(foregroundColor)
                .padding(size.padding)
                .frame(minHeight: size.height)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
    @State private var isPressed = false
    private var labelFont: Font {
        switch size {
        case .small: return .labelSmall
        case .medium: return .labelMedium  
        case .large: return .labelLarge
        }
    }
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primaryAccent
        case .ghost: return .primary
        case .danger: return .white
        }
    }
    private var backgroundColor: Color {
        switch style {
        case .primary: return .primaryAccent
        case .secondary: return .primaryAccent.opacity(0.1)
        case .ghost: return .clear
        case .danger: return .materialRed
        }
    }
}
// MARK: - 悬浮操作按钮
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var style: FABStyle = .primary
    var size: FABSize = .regular
    enum FABStyle {
        case primary
        case secondary
        case surface
    }
    enum FABSize {
        case small
        case regular
        case large
        case extended
        var diameter: CGFloat {
            switch self {
            case .small: return 40
            case .regular: return 56
            case .large: return 96
            case .extended: return 56
            }
        }
    }
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size.diameter, height: size.diameter)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(color: ShadowStyle.medium.color, radius: ShadowStyle.medium.radius, x: ShadowStyle.medium.x, y: ShadowStyle.medium.y)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3), value: isPressed)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
    @State private var isPressed = false
    private var iconSize: CGFloat {
        switch size {
        case .small: return 18
        case .regular: return 24
        case .large: return 32
        case .extended: return 24
        }
    }
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primaryAccent
        case .surface: return .primaryAccent
        }
    }
    private var backgroundColor: Color {
        switch style {
        case .primary: return .primaryAccent
        case .secondary: return .surfaceSecondary
        case .surface: return .surfacePrimary
        }
    }
}
// MARK: - 现代进度指示器
struct ModernProgressIndicator: View {
    let progress: Double
    var style: ProgressStyle = .linear
    var color: Color = .primaryAccent
    enum ProgressStyle {
        case linear
        case circular
    }
    var body: some View {
        switch style {
        case .linear:
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 2.0)
        case .circular:
            ProgressView(value: progress)
                .progressViewStyle(CircularProgressViewStyle(tint: color))
        }
    }
}
// MARK: - 现代搜索栏
struct ModernSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    var placeholder: String = "Search"
    var onSubmit: () -> Void = {}
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16, weight: .medium))
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .font(.bodyMedium)
                .onSubmit(onSubmit)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(isFocused ? Color.primaryAccent : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
// MARK: - 动画预设
extension Animation {
    static let modernSpring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)
    static let modernEaseInOut = Animation.easeInOut(duration: 0.3)
    static let modernBounce = Animation.interpolatingSpring(stiffness: 170, damping: 15)
}
// MARK: - 视图修饰符
extension View {
    func modernCardStyle() -> some View {
        self.modifier(ModernCardStyleModifier())
    }
    func modernGlassEffect() -> some View {
        self.modifier(GlassEffectModifier())
    }
}
struct ModernCardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            .shadow(color: ShadowStyle.soft.color, radius: ShadowStyle.soft.radius, x: ShadowStyle.soft.x, y: ShadowStyle.soft.y)
    }
}
struct GlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}