import Foundation
import SwiftUI
import os.log

/// 文件导入管理器，提供统一的文件导入进度和错误处理
@MainActor
final class FileImportManager: ObservableObject {
    static let shared = FileImportManager()
    
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var currentFileName: String = ""
    @Published var importStatus: ImportStatus = .idle
    @Published var errorMessage: String?
    
    private let logger = Logger(subsystem: "com.feather.fileimport", category: "FileImportManager")
    
    enum ImportStatus {
        case idle
        case copying
        case extracting
        case moving
        case addingToDatabase
        case completed
        case failed
        
        var description: String {
            switch self {
            case .idle: return "准备中"
            case .copying: return "复制文件"
            case .extracting: return "解压文件"
            case .moving: return "移动文件"
            case .addingToDatabase: return "添加到数据库"
            case .completed: return "导入完成"
            case .failed: return "导入失败"
            }
        }
    }
    
    private init() {}
    
    /// 导入单个文件
    func importFile(_ url: URL) {
        guard !isImporting else {
            logger.warning("已有文件正在导入中")
            return
        }
        
        logger.info("开始导入文件: \(url.lastPathComponent)")
        
        isImporting = true
        importProgress = 0.0
        currentFileName = url.lastPathComponent
        importStatus = .idle
        errorMessage = nil
        
        Task {
            await performImport(url: url)
        }
    }
    
    /// 导入多个文件
    func importFiles(_ urls: [URL]) {
        guard !isImporting else {
            logger.warning("已有文件正在导入中")
            return
        }
        
        guard !urls.isEmpty else {
            logger.warning("没有文件需要导入")
            return
        }
        
        logger.info("开始导入 \(urls.count) 个文件")
        
        isImporting = true
        importProgress = 0.0
        currentFileName = "\(urls.count) 个文件"
        importStatus = .idle
        errorMessage = nil
        
        Task {
            await performMultipleImport(urls: urls)
        }
    }
    
    /// 执行单个文件导入
    private func performImport(url: URL) async {
        // 创建Download对象用于进度跟踪
        let download = Download(id: "ManualImport_\(UUID().uuidString)", url: url, onlyArchiving: true)
        
        // 步骤1: 复制文件
        importStatus = .copying
        importProgress = 0.1
        logger.info("步骤1: 复制文件")
        
        // 步骤2: 解压文件
        importStatus = .extracting
        importProgress = 0.3
        logger.info("步骤2: 解压文件")
        
        // 步骤3: 移动文件
        importStatus = .moving
        importProgress = 0.7
        logger.info("步骤3: 移动文件")
        
        // 步骤4: 添加到数据库
        importStatus = .addingToDatabase
        importProgress = 0.9
        logger.info("步骤4: 添加到数据库")
        
        // 使用FR.handlePackageFile进行实际处理
        await withCheckedContinuation { continuation in
            FR.handlePackageFile(url, download: download) { error in
                Task { @MainActor in
                    if let error = error {
                        self.logger.error("文件导入失败: \(error.localizedDescription)")
                        self.importStatus = .failed
                        self.errorMessage = error.localizedDescription
                    } else {
                        self.logger.info("文件导入成功: \(url.lastPathComponent)")
                        self.importStatus = .completed
                        self.importProgress = 1.0
                    }
                    
                    // 延迟一下让用户看到完成状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.isImporting = false
                        self.importProgress = 0.0
                        self.currentFileName = ""
                        self.importStatus = .idle
                        self.errorMessage = nil
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    /// 执行多个文件导入
    private func performMultipleImport(urls: [URL]) async {
        let totalFiles = urls.count
        
        for (index, url) in urls.enumerated() {
            currentFileName = "\(url.lastPathComponent) (\(index + 1)/\(totalFiles))"
            importProgress = Double(index) / Double(totalFiles)
            
            await performImport(url: url)
            
            // 如果导入失败，停止后续导入
            if importStatus == .failed {
                break
            }
        }
        
        if importStatus != .failed {
            importStatus = .completed
            importProgress = 1.0
            currentFileName = "所有文件导入完成"
        }
        
        // 延迟一下让用户看到完成状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isImporting = false
            self.importProgress = 0.0
            self.currentFileName = ""
            self.importStatus = .idle
            self.errorMessage = nil
        }
    }
    
    /// 取消导入
    func cancelImport() {
        logger.info("用户取消了文件导入")
        isImporting = false
        importProgress = 0.0
        currentFileName = ""
        importStatus = .idle
        errorMessage = nil
    }
}

/// 文件导入进度视图
struct FileImportProgressView: View {
    @StateObject private var importManager = FileImportManager.shared
    
    var body: some View {
        if importManager.isImporting {
            VStack(spacing: 12) {
                HStack {
                    ProgressView(value: importManager.importProgress)
                        .progressViewStyle(.linear)
                        .frame(height: 8)
                    
                    Text("\(Int(importManager.importProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(importManager.currentFileName)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Text(importManager.importStatus.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let errorMessage = importManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
}
