//
//  ThemeTestView.swift
//  APP
//
//  Created by pxx917144686 on 2025/08/29.
//  主题测试视图 - 用于验证深色模式切换
//
import SwiftUI

struct ThemeTestView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingThemeSelector = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 当前主题显示
            VStack(spacing: 10) {
                Text("当前主题")
                    .font(.headline)
                Text(themeManager.selectedTheme.rawValue)
                    .font(.title)
                    .foregroundColor(themeManager.accentColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
            )
            
            // 主题切换按钮
            Button("切换主题") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    themeManager.selectedTheme = themeManager.selectedTheme == .light ? .dark : .light
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(themeManager.accentColor)
            
            // 显示主题选择器
            Button("显示主题选择器") {
                showingThemeSelector = true
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .padding()
        .background(themeManager.backgroundColor)
        .sheet(isPresented: $showingThemeSelector) {
            FloatingThemeSelector(isPresented: $showingThemeSelector)
                .environmentObject(themeManager)
        }
    }
}

#Preview {
    ThemeTestView()
        .environmentObject(ThemeManager.shared)
}
