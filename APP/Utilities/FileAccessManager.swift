import Foundation
import UIKit
import os.log

/// 文件访问管理器，专门处理LaunchServices错误和文件访问权限问题
@MainActor
final class FileAccessManager: @unchecked Sendable {
    static let shared = FileAccessManager()
    private let logger = Logger(subsystem: "com.feather.fileaccess", category: "FileAccessManager")
    
    private init() {
        logger.info("FileAccessManager initialized")
    }
    
    /// 安全地处理文件访问，避免LaunchServices错误
    func handleFileAccessSafely(for urls: [URL], completion: @escaping ([URL]) -> Void) {
        logger.info("开始安全文件访问处理，文件数量: \(urls.count)")
        
        Task {
            var accessibleUrls: [URL] = []
            
            await withTaskGroup(of: (URL, Bool).self) { group in
                for url in urls {
                    group.addTask {
                        return await withCheckedContinuation { continuation in
                            Task {
                                await self.processFileAccess(url: url) { isAccessible in
                                    continuation.resume(returning: (url, isAccessible))
                                }
                            }
                        }
                    }
                }
                
                for await (url, isAccessible) in group {
                    if isAccessible {
                        accessibleUrls.append(url)
                    }
                }
            }
            
            await MainActor.run {
                self.logger.info("文件访问处理完成，成功访问 \(accessibleUrls.count)/\(urls.count) 个文件")
                completion(accessibleUrls)
            }
        }
    }
    
    /// 处理单个文件的访问
    private func processFileAccess(url: URL, completion: @escaping @Sendable (Bool) -> Void) async {
        logger.info("处理文件访问: \(url.lastPathComponent)")
        
        // 方法1: 尝试安全范围资源访问（优先处理，因为这是从文档选择器来的文件）
        if await trySecurityScopedAccess(url: url) {
            logger.info("安全范围访问成功: \(url.lastPathComponent)")
            completion(true)
            return
        }
        
        // 方法2: 尝试直接访问（适用于本地文件）
        if await tryDirectAccess(url: url) {
            logger.info("直接访问成功: \(url.lastPathComponent)")
            completion(true)
            return
        }
        
        // 方法3: 尝试复制到临时目录
        if await tryCopyToTempDirectory(url: url) {
            logger.info("复制到临时目录成功: \(url.lastPathComponent)")
            completion(true)
            return
        }
        
        logger.error("所有文件访问方法都失败: \(url.lastPathComponent)")
        completion(false)
    }
    
    /// 尝试直接访问文件
    private func tryDirectAccess(url: URL) async -> Bool {
        return await withCheckedContinuation { continuation in
            Task.detached {
                let isAccessible = FileManager.default.fileExists(atPath: url.path) && 
                                 FileManager.default.isReadableFile(atPath: url.path)
                continuation.resume(returning: isAccessible)
            }
        }
    }
    
    /// 尝试安全范围资源访问
    private func trySecurityScopedAccess(url: URL) async -> Bool {
        return await withCheckedContinuation { continuation in
            Task.detached {
                var isAccessible = false
                var didStartAccessing = false
                
                // 尝试启动安全范围资源访问
                if url.startAccessingSecurityScopedResource() {
                    didStartAccessing = true
                    self.logger.info("启动安全范围资源访问: \(url.lastPathComponent)")
                    
                    // 等待系统处理权限，增加等待时间
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
                    
                    // 验证文件访问
                    if FileManager.default.fileExists(atPath: url.path) {
                        do {
                            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                            let fileSize = attributes[.size] as? Int64 ?? 0
                            isAccessible = fileSize > 0
                            
                            if isAccessible {
                                self.logger.info("安全范围访问验证成功: \(url.lastPathComponent), 文件大小: \(fileSize) bytes")
                                
                                // 尝试读取文件内容以进一步验证访问权限
                                do {
                                    let _ = try Data(contentsOf: url, options: .mappedIfSafe)
                                    self.logger.info("文件内容读取成功: \(url.lastPathComponent)")
                                } catch {
                                    self.logger.warning("文件内容读取失败，但文件存在: \(url.lastPathComponent), 错误: \(error.localizedDescription)")
                                    // 即使内容读取失败，如果文件存在且大小>0，仍然认为可访问
                                }
                            } else {
                                self.logger.warning("文件存在但大小为0: \(url.lastPathComponent)")
                            }
                        } catch {
                            self.logger.error("安全范围访问验证失败: \(url.lastPathComponent), 错误: \(error.localizedDescription)")
                        }
                    } else {
                        self.logger.warning("安全范围访问启动后文件不存在: \(url.lastPathComponent)")
                    }
                } else {
                    self.logger.warning("无法启动安全范围资源访问: \(url.lastPathComponent)")
                }
                
                // 注意：这里不调用stopAccessingSecurityScopedResource()，因为调用者需要保持访问权限
                // 调用者负责在适当时机停止访问
                
                continuation.resume(returning: isAccessible)
            }
        }
    }
    
    /// 尝试复制到临时目录
    private func tryCopyToTempDirectory(url: URL) async -> Bool {
        return await withCheckedContinuation { continuation in
            Task.detached {
                let tempDir = FileManager.default.temporaryDirectory
                let tempFile = tempDir.appendingPathComponent("\(UUID().uuidString)_\(url.lastPathComponent)")
                
                do {
                    // 尝试复制文件
                    try FileManager.default.copyItem(at: url, to: tempFile)
                    
                    // 验证复制是否成功
                    let isAccessible = FileManager.default.fileExists(atPath: tempFile.path)
                    
                    if isAccessible {
                        self.logger.info("文件复制到临时目录成功: \(url.lastPathComponent)")
                        // 注意：这里不删除临时文件，让调用者处理
                    } else {
                        self.logger.error("文件复制到临时目录失败: \(url.lastPathComponent)")
                    }
                    
                    continuation.resume(returning: isAccessible)
                } catch {
                    self.logger.error("复制文件到临时目录时出错: \(url.lastPathComponent), 错误: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    /// 清理临时文件
    func cleanupTempFiles() {
        Task.detached {
            let tempDir = FileManager.default.temporaryDirectory
            do {
                let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                for file in tempFiles {
                    if file.lastPathComponent.contains("_") && 
                       (file.pathExtension == "ipa" || file.pathExtension == "tipa") {
                        try? FileManager.default.removeItem(at: file)
                        self.logger.info("清理临时文件: \(file.lastPathComponent)")
                    }
                }
            } catch {
                self.logger.error("清理临时文件时出错: \(error.localizedDescription)")
            }
        }
    }
    
    /// 获取文件访问状态
    func getFileAccessStatus(for url: URL) -> FileAccessStatus {
        if FileManager.default.fileExists(atPath: url.path) {
            if FileManager.default.isReadableFile(atPath: url.path) {
                return .accessible
            } else {
                return .notReadable
            }
        } else {
            return .notFound
        }
    }
}

/// 文件访问状态
enum FileAccessStatus {
    case accessible
    case notFound
    case notReadable
    case permissionDenied
    
    var description: String {
        switch self {
        case .accessible: return "可访问"
        case .notFound: return "文件不存在"
        case .notReadable: return "文件不可读"
        case .permissionDenied: return "权限被拒绝"
        }
    }
}
