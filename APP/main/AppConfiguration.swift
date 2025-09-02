//
//  Created by pxx917144686 on 2025/08/20.
//
import SwiftUI
import Foundation
class AppConfiguration {
    static let shared = AppConfiguration()
    let bundleIdentifier = Bundle.main.bundleIdentifier!
    let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("APP")
    let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(Bundle.main.bundleIdentifier!)
    private init() {}
    func initialize() {
        setupDirectories()
        setupTheme()
    }
    private func setupDirectories() {
        if !FileManager.default.fileExists(atPath: documentsDirectory.path) {
            try? FileManager.default.createDirectory(
                at: documentsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        if !FileManager.default.fileExists(atPath: temporaryDirectory.path) {
            try? FileManager.default.createDirectory(
                at: temporaryDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        try? FileManager.default.removeItem(at: temporaryDirectory)
        try? FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    private func setupTheme() {
        // 确保应用启动时默认为浅色模式
        // 只有在用户明确设置过深色模式时才使用深色模式
        if UserDefaults.standard.string(forKey: "SelectedTheme") == nil {
            ThemeManager.shared.resetToDefaultTheme()
        }
        print("Theme initialized: \(ThemeManager.shared.selectedTheme.rawValue)")
    }
}
