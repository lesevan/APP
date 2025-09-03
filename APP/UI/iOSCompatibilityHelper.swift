//
//  iOSCompatibilityHelper.swift
//  APP
//
//  Created by pxx917144686 on 2025/08/29.
//  iOS兼容性辅助工具 - 解决多机型界面显示问题
//
import SwiftUI
import Foundation

// MARK: - 设备类型枚举
enum DeviceType {
    case iPhone8, iPhone8Plus, iPhoneX, iPhone12, iPhone14Pro, iPhoneXSMax, iPhone12ProMax, iPhone14ProMax, iPhone13
}

// MARK: - 设备适配器
struct DeviceAdapter {
    static let shared: DeviceAdapter = DeviceAdapter()
    
    private init() {}
    
    // 获取设备类型
    var deviceType: DeviceType {
        #if canImport(UIKit)
        let screenHeight = UIScreen.main.bounds.height
        switch screenHeight {
        case 667: return .iPhone8 // iPhone 8, SE2
        case 736: return .iPhone8Plus // iPhone 8 Plus
        case 812: return .iPhoneX // iPhone X, XS, 11 Pro, 12 mini, 13 mini
        case 844: return .iPhone12 // iPhone 12, 12 Pro, 13, 13 Pro, 14
        case 852: return .iPhone14Pro // iPhone 14 Pro
        case 896: return .iPhoneXSMax // iPhone XS Max, 11, 11 Pro Max
        case 926: return .iPhone12ProMax // iPhone 12 Pro Max, 13 Pro Max, 14 Plus
        case 932: return .iPhone14ProMax // iPhone 14 Pro Max
        default: return .iPhone13 // 默认使用iPhone 13尺寸
        }
        #else
        return .iPhone13
        #endif
    }
    
    // 在DeviceAdapter中添加TrollStore检测
    var isTrollStoreEnvironment: Bool {
        #if canImport(UIKit)
        // 检测是否为TrollStore环境
        let bundlePath = Bundle.main.bundlePath
        return bundlePath.contains("TrollStore") || bundlePath.contains("trollstore")
        #else
        return false
        #endif
    }
    
    // 修改安全区域获取逻辑
    var safeAreaTop: CGFloat {
        #if canImport(UIKit)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let safeArea = windowScene.windows.first?.safeAreaInsets.top ?? 0
            // TrollStore环境下使用备用值
            if isTrollStoreEnvironment && safeArea == 0 {
                return 44 // 默认安全区域顶部高度
            }
            return safeArea
        }
        return 0
        #else
        return 0
        #endif
    }
    
    var safeAreaBottom: CGFloat {
        #if canImport(UIKit)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first?.safeAreaInsets.bottom ?? 0
        }
        return 0
        #else
        return 0
        #endif
    }
}

// MARK: - iOS版本检测
struct iOSVersionChecker {
    static let shared = iOSVersionChecker()
    
    var isIOS18: Bool {
        if #available(iOS 18.0, *) {
            return true
        }
        return false
    }
    
    var isIOS17: Bool {
        if #available(iOS 17.0, *) {
            return true
        }
        return false
    }
    
    var isIOS16: Bool {
        if #available(iOS 16.0, *) {
            return true
        }
        return false
    }
}

// MARK: - 设备特定修复
struct DeviceSpecificFixes {
    static let shared = DeviceSpecificFixes()
    
    // 获取设备特定的修复参数
    func getFixParameters() -> DeviceFixParameters {
        let deviceType = DeviceAdapter.shared.deviceType
        let isIOS18 = iOSVersionChecker.shared.isIOS18
        let isTrollStore = DeviceAdapter.shared.isTrollStoreEnvironment
        
        // TrollStore环境优先使用专用修复参数
        if isTrollStore {
            return getTrollStoreFixParameters()
        }
        
        switch deviceType {
        case .iPhone8, .iPhone8Plus:
            return DeviceFixParameters(
                safeAreaTop: 20,
                safeAreaBottom: 0,
                tabBarHeight: 49,
                statusBarHeight: 20,
                needsSpecialHandling: false
            )
        case .iPhoneX, .iPhone12, .iPhone13:
            return DeviceFixParameters(
                safeAreaTop: 44,
                safeAreaBottom: 34,
                tabBarHeight: 83,
                statusBarHeight: 44,
                needsSpecialHandling: isIOS18
            )
        case .iPhone14Pro, .iPhone14ProMax:
            return DeviceFixParameters(
                safeAreaTop: 47,
                safeAreaBottom: 34,
                tabBarHeight: 83,
                statusBarHeight: 47,
                needsSpecialHandling: isIOS18
            )
        default:
            return DeviceFixParameters(
                safeAreaTop: 44,
                safeAreaBottom: 34,
                tabBarHeight: 83,
                statusBarHeight: 44,
                needsSpecialHandling: isIOS18
            )
        }
    }

    // 在DeviceSpecificFixes中添加TrollStore修复
    func getTrollStoreFixParameters() -> DeviceFixParameters {
        return DeviceFixParameters(
            safeAreaTop: 44,
            safeAreaBottom: 34,
            tabBarHeight: 83,
            statusBarHeight: 44,
            needsSpecialHandling: true
        )
    }
}

struct DeviceFixParameters {
    let safeAreaTop: CGFloat
    let safeAreaBottom: CGFloat
    let tabBarHeight: CGFloat
    let statusBarHeight: CGFloat
    let needsSpecialHandling: Bool
}

// MARK: - 界面修复修饰符
struct iOSCompatibilityModifier: ViewModifier {
    let deviceType: DeviceType
    let isIOS18: Bool
    
    init() {
        self.deviceType = DeviceAdapter.shared.deviceType
        self.isIOS18 = iOSVersionChecker.shared.isIOS18
    }
    
    func body(content: Content) -> some View {
        content
            .background(Color.clear) // 确保背景透明
            .clipped() // 防止内容溢出
            .allowsHitTesting(true) // 确保触摸事件正常
    }
}

// MARK: - 安全区域修复
struct SafeAreaFixModifier: ViewModifier {
    let edges: Edge.Set
    let deviceType: DeviceType
    
    init(edges: Edge.Set = .all, deviceType: DeviceType) {
        self.edges = edges
        self.deviceType = deviceType
    }
    
    func body(content: Content) -> some View {
        if deviceType == .iPhone14Pro || deviceType == .iPhone14ProMax {
            // iPhone 14 Pro系列特殊处理
            content
                .padding(.top, DeviceAdapter.shared.safeAreaTop)
                .padding(.bottom, DeviceAdapter.shared.safeAreaBottom)
        } else {
            // 简化处理，直接使用.all
            content.ignoresSafeArea(.all)
        }
    }
}

// MARK: - 动画修复
struct AnimationFixModifier: ViewModifier {
    let isIOS18: Bool
    
    init() {
        self.isIOS18 = iOSVersionChecker.shared.isIOS18
    }
    
    func body(content: Content) -> some View {
        if isIOS18 {
            // iOS 18使用更稳定的动画
            content
                .animation(.easeInOut(duration: 0.25), value: true)
        } else {
            // 旧版本iOS使用标准动画
            content
                .animation(.easeInOut(duration: 0.3), value: true)
        }
    }
}

// MARK: - 布局修复
struct LayoutFixModifier: ViewModifier {
    let deviceType: DeviceType
    let isIOS18: Bool
    
    init() {
        self.deviceType = DeviceAdapter.shared.deviceType
        self.isIOS18 = iOSVersionChecker.shared.isIOS18
    }
    
    func body(content: Content) -> some View {
        if isIOS18 && (deviceType == .iPhone14Pro || deviceType == .iPhone14ProMax) {
            // iOS 18 + iPhone 14 Pro系列特殊布局处理
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            content
        }
    }
}

// MARK: - 视图扩展
extension View {
    /// 应用iOS兼容性修复
    func iOSCompatibility() -> some View {
        self.modifier(iOSCompatibilityModifier())
    }
    
    /// 应用安全区域修复
    func safeAreaFix(edges: Edge.Set = .all) -> some View {
        self.modifier(SafeAreaFixModifier(edges: edges, deviceType: DeviceAdapter.shared.deviceType))
    }
    
    /// 应用动画修复
    func animationFix() -> some View {
        self.modifier(AnimationFixModifier())
    }
    
    /// 应用布局修复
    func layoutFix() -> some View {
        self.modifier(LayoutFixModifier())
    }
}

// MARK: - 颜色修复
extension Color {
    /// 获取设备适配的颜色
    static func deviceAdaptive(_ light: Color, dark: Color) -> Color {
        let deviceType = DeviceAdapter.shared.deviceType
        let isIOS18 = iOSVersionChecker.shared.isIOS18
        
        // iOS 18上某些设备可能需要特殊颜色处理
        if isIOS18 && (deviceType == .iPhone14Pro || deviceType == .iPhone14ProMax) {
            return dark
        }
        
        // 注意：这里需要确保ThemeManager可用
        // 如果ThemeManager不可用，可以暂时返回默认值
        return light
    }
}

// MARK: - 字体修复
extension Font {
    /// 获取设备适配的字体
    static func deviceAdaptive(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let deviceType = DeviceAdapter.shared.deviceType
        let isIOS18 = iOSVersionChecker.shared.isIOS18
        
        var adjustedSize = size
        
        // iOS 18上某些设备可能需要字体大小调整
        if isIOS18 {
            switch deviceType {
            case .iPhone14Pro, .iPhone14ProMax:
                adjustedSize = size * 1.05 // 稍微增大字体
            case .iPhone8, .iPhone8Plus:
                adjustedSize = size * 0.95 // 稍微减小字体
            default:
                break
            }
        }
        
        return .system(size: adjustedSize, weight: weight)
    }
}
