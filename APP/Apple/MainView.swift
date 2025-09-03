//
//  MainView.swift
//  APP
//
//  Created by pxx917144686 on 2025/08/29.
//
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// 确保能访问设备适配器
// 注意：DeviceAdapter和DeviceType定义在iOSCompatibilityHelper.swift中
// 注意：ModernDarkColors定义在Colors.swift中

struct MainView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 2 // 默认选中管理页面
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var liquidOffset: CGFloat = 0 // Liquid Glass 液体偏移
    @State private var scrollOffset: CGFloat = 0 // 滚动偏移，用于标签栏最小化
    @State private var isTabBarMinimized = false // 标签栏是否最小化
    
    var body: some View {
        ZStack {
            // 主内容区域
            TabView(selection: $selectedTab) {
                // 账户界面
                AccountView()
                    .tag(0)
                // 搜索界面
                SearchView()
                    .tag(1)
                // 管理界面
                DownloadView()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .accentColor(themeManager.accentColor)
            .environmentObject(themeManager)
            .environmentObject(AppStore.this)
            // 添加滑动切换功能
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.width
                        // Liquid Glass 液体效果
                        liquidOffset = value.translation.width * 0.3
                    }
                    .onEnded { value in
                        isDragging = false
                        let threshold: CGFloat = 50
                        if value.translation.width > threshold && selectedTab > 0 {
                            // 向右滑动，切换到上一个标签
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab -= 1
                            }
                        } else if value.translation.width < -threshold && selectedTab < 2 {
                            // 向左滑动，切换到下一个标签
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab += 1
                            }
                        }
                        // 重置拖拽偏移和液体效果
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dragOffset = 0
                            liquidOffset = 0
                        }
                    }
            )
            
            // 铺满底部栏的分段式设计
            VStack {
                Spacer()
                // 铺满底部栏的分段控制器
                ModernSegmentedTabBar(
                    selectedTab: $selectedTab, 
                    isDragging: $isDragging, 
                    dragOffset: $dragOffset,
                    liquidOffset: $liquidOffset,
                    isMinimized: $isTabBarMinimized
                )
                .animation(.easeInOut(duration: 0.3), value: isTabBarMinimized)
            }
            .ignoresSafeArea(.container, edges: .bottom) // 使用标准的ignoresSafeArea
        }
        .background(themeManager.backgroundColor)
        .ignoresSafeArea()
        .modifier(TrollStoreCompatibilityModifier()) // 新增
    }
}

// MARK: - 现代化分段控制器底部栏
struct ModernSegmentedTabBar: View {
    @Binding var selectedTab: Int
    @Binding var isDragging: Bool
    @Binding var dragOffset: CGFloat
    @Binding var liquidOffset: CGFloat
    @Binding var isMinimized: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    private let tabItems = [
        (title: "账户", icon: "person.crop.circle.fill", color: Color.blue),
        (title: "搜索", icon: "magnifyingglass", color: Color.green),
        (title: "管理", icon: "arrow.down.circle.fill", color: Color.orange)
    ]
    
    // 简化标签栏高度设置，避免设备类型检测问题
    private var tabBarHeight: CGFloat {
        #if canImport(UIKit)
        // 使用现代的安全区域检测方法
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let safeAreaBottom = window.safeAreaInsets.bottom
            return 80 + safeAreaBottom
        }
        return 80
        #else
        return 80
        #endif
    }
    
    var body: some View {
        // 铺满底部栏的分段控制器容器
        HStack(spacing: 0) {
            ForEach(0..<tabItems.count, id: \.self) { index in
                ModernSegmentedTabItem(
                    title: tabItems[index].title,
                    icon: tabItems[index].icon,
                    color: tabItems[index].color,
                    isSelected: selectedTab == index,
                    isDragging: isDragging,
                    dragOffset: dragOffset,
                    liquidOffset: liquidOffset,
                    tabIndex: index,
                    isMinimized: isMinimized
                ) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        selectedTab = index
                    }
                }
            }
        }
        .background(
            // 铺满底部栏的背景层 - 适配深色模式
            Rectangle()
                .fill(themeManager.selectedTheme == .dark ? 
                     ModernDarkColors.surfacePrimary : 
                     Color.white)
        )
        .overlay(
            // 顶部边框 - 深色模式下更明显
            Rectangle()
                .fill(themeManager.selectedTheme == .dark ? 
                     ModernDarkColors.borderPrimary : 
                     Color.gray.opacity(0.2))
                .frame(height: 0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        )
        .shadow(
            color: themeManager.selectedTheme == .dark ? 
                ModernDarkColors.shadowColor : 
                Color.black.opacity(0.1),
            radius: themeManager.selectedTheme == .dark ? 8 : 4,
            x: 0,
            y: -2
        )
        .frame(maxWidth: .infinity) // 铺满宽度
        .frame(height: tabBarHeight) // 动态调整高度
        .scaleEffect(isMinimized ? 0.95 : 1.0)
        .opacity(isMinimized ? 0.9 : 1.0)
        .clipped() // 确保内容不溢出
    }
}

// MARK: - 现代化分段控制器项目
struct ModernSegmentedTabItem: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let isDragging: Bool
    let dragOffset: CGFloat
    let liquidOffset: CGFloat
    let tabIndex: Int
    let isMinimized: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    // 分段控制器进度计算
    private var segmentProgress: CGFloat {
        guard isDragging else { return 0 }
        #if canImport(UIKit)
        let normalizedOffset = dragOffset / UIScreen.main.bounds.width
        #else
        let normalizedOffset = dragOffset / 390 // 默认宽度
        #endif
        let tabProgress = CGFloat(tabIndex) + normalizedOffset
        return max(0, min(1, 1 - abs(tabProgress - CGFloat(tabIndex))))
    }
    
    // 现代化变形效果
    private var modernScale: CGFloat {
        if isSelected {
            return isDragging ? 1.15 : 1.05
        } else {
            return isDragging ? 0.9 + segmentProgress * 0.1 : 0.9
        }
    }
    
    // 现代化透明度
    private var modernOpacity: Double {
        if isSelected {
            return 1.0
        } else {
            return isDragging ? 0.6 + segmentProgress * 0.4 : 0.6
        }
    }
    
    // 简化图标大小设置，避免设备类型检测问题
    private var iconSize: CGFloat {
        #if canImport(UIKit)
        // 根据屏幕尺寸动态调整
        let screenHeight = UIScreen.main.bounds.height
        if screenHeight <= 667 { // iPhone 8及以下
            return 20
        } else if screenHeight >= 852 { // iPhone 14 Pro及以上
            return 24
        } else {
            return 22
        }
        #else
        return 22
        #endif
    }
    
    // 简化字体大小设置，避免设备类型检测问题
    private var titleFontSize: CGFloat {
        #if canImport(UIKit)
        // 根据屏幕尺寸动态调整
        let screenHeight = UIScreen.main.bounds.height
        if screenHeight <= 667 { // iPhone 8及以下
            return 11
        } else if screenHeight >= 852 { // iPhone 14 Pro及以上
            return 13
        } else {
            return 12
        }
        #else
        return 12
        #endif
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 铺满底部栏的分段背景
                if isSelected {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.3),
                                    color.opacity(0.1),
                                    color.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .background(
                            Rectangle()
                                .fill(themeManager.selectedTheme == .dark ? 
                                     ModernDarkColors.surfaceSecondary.opacity(0.9) : 
                                     Color.white.opacity(0.9))
                                .blur(radius: 8)
                        )
                        .overlay(
                            // 顶部高亮边框
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            color.opacity(0.8),
                                            color.opacity(0.4),
                                            color.opacity(0.2)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 3)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        )
                        .scaleEffect(modernScale)
                        .animation(.easeInOut(duration: 0.3), value: isSelected)
                }
                
                // 铺满底部栏的内容层
                VStack(spacing: 4) {
                    // 图标
                    ZStack {
                        // 图标光晕效果
                        if isSelected {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            color.opacity(0.4),
                                            color.opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 3,
                                        endRadius: 20
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .scaleEffect(modernScale)
                        }
                        
                        // 主图标
                        Image(systemName: icon)
                            .font(.system(size: iconSize, weight: isSelected ? .bold : .semibold))
                            .foregroundColor(isSelected ? color : (themeManager.selectedTheme == .dark ? 
                                 color.opacity(0.8) : 
                                 color.opacity(0.7)))
                            .scaleEffect(modernScale)
                            .opacity(modernOpacity)
                    }
                    
                    // 文字
                    Text(title)
                        .font(.system(size: titleFontSize, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? color : (themeManager.selectedTheme == .dark ? 
                             color.opacity(0.8) : 
                             color.opacity(0.7)))
                        .opacity(modernOpacity)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .iOSCompatibility()
    }
}

// 新增TrollStore兼容性修饰符
struct TrollStoreCompatibilityModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // TrollStore环境下的特殊处理
                if DeviceAdapter.shared.isTrollStoreEnvironment {
                    // 强制刷新布局
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // 触发视图更新
                    }
                }
            }
    }
}