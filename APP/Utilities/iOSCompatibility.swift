import Foundation
import UniformTypeIdentifiers
import UIKit
import os.log

enum FileImportError: LocalizedError {
    case fileNotFound
    case accessFailed
    case invalidFileType(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "未选择文件或文件不存在。"
        case .accessFailed: return "无法访问文件，可能需要权限。"
        case .invalidFileType(let type): return "不支持的文件类型: \(type)。"
        case .unknown: return "发生未知文件导入错误。"
        }
    }
}

/// 提供iOS版本兼容性处理的工具类
@MainActor
final class iOSCompatibility: @unchecked Sendable {
    static let shared = iOSCompatibility()
    private let logger = Logger(subsystem: "com.feather.ioscompatibility", category: "iOSCompatibility")

    private init() {
        logger.info("iOSCompatibility initialized. Current iOS version: \(UIDevice.current.systemVersion)")
    }

    /// 根据iOS版本创建UIDocumentPickerViewController
    func createDocumentPicker(for contentTypes: [UTType], allowsMultipleSelection: Bool) -> UIDocumentPickerViewController {
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        } else {
            picker = UIDocumentPickerViewController(documentTypes: contentTypes.map { $0.identifier }, in: .import)
        }
        picker.allowsMultipleSelection = allowsMultipleSelection
        
        // 设置模态呈现样式以避免LaunchServices问题
        picker.modalPresentationStyle = .formSheet
        
        logger.info("创建UIDocumentPickerViewController，允许多选: \(allowsMultipleSelection)")
        return picker
    }

    /// 处理文件导入后的安全范围访问权限
    func handleFileImportPermissions(for urls: [URL], completion: @escaping ([URL]) -> Void) {
        logger.info("直接返回文件URL，因为使用了asCopy: true")
        // 由于使用了asCopy: true，文件已经被复制到应用的沙盒中，不需要特殊处理
        completion(urls)
    }
    
    /// 处理LaunchServices错误，提供降级方案
    func handleLaunchServicesError(_ error: Error, for url: URL) -> Bool {
        logger.warning("检测到LaunchServices错误: \(error.localizedDescription)")
        
        // 检查是否是权限相关的错误
        if let nsError = error as NSError? {
            if nsError.domain == "NSOSStatusErrorDomain" && nsError.code == -54 {
                logger.warning("LaunchServices数据库映射失败，尝试替代方案")
                
                // 尝试直接文件访问作为降级方案
                if FileManager.default.fileExists(atPath: url.path) {
                    logger.info("使用直接文件访问作为降级方案")
                    return true
                }
            }
        }
        
        return false
    }

    /// 验证文件类型是否符合预期，通过文件扩展名和文件头（magic bytes）
    func validateFileType(_ url: URL, allowedTypes: [String]) -> Bool {
        guard allowedTypes.contains(url.pathExtension.lowercased()) else {
            logger.warning("文件扩展名不匹配: \(url.pathExtension), 允许的类型: \(allowedTypes.joined(separator: ", "))")
            return false
        }

        // 进一步通过文件头验证，防止恶意文件或错误的文件扩展名
        do {
            let fileHandle = try FileHandle(forReadingFrom: url)
            let magicBytes = try fileHandle.read(upToCount: 16) // 读取文件的前16个字节
            try fileHandle.close()

            guard let bytes = magicBytes else {
                logger.error("无法读取文件头: \(url.lastPathComponent)")
                return false
            }

            let hexString = bytes.map { String(format: "%02hhx", $0) }.joined()
            logger.info("文件 \(url.lastPathComponent) 的文件头: \(hexString)")

            switch url.pathExtension.lowercased() {
            case "ipa", "tipa":
                // IPA文件实际上是ZIP文件，其文件头通常是PK (504b)
                return hexString.hasPrefix("504b0304") || hexString.hasPrefix("504b0506") || hexString.hasPrefix("504b0708")
            case "dylib", "deb":
                // Dylib和Deb文件通常是Mach-O格式，文件头是FEEDFACE或FEEDFACF (arm64)
                // Deb文件也是ar归档，文件头是!ar (21637268)
                return hexString.hasPrefix("feedface") || hexString.hasPrefix("feedfacf") || hexString.hasPrefix("213c617263683e") // !<arch>
            case "p12":
                // P12文件是PKCS#12格式，通常以3082开头
                return hexString.hasPrefix("3082")
            case "mobileprovision":
                // Mobileprovision文件是ASN.1编码的plist，通常以3080开头
                return hexString.hasPrefix("3080") || hexString.hasPrefix("3081") || hexString.hasPrefix("3082")
            case "xml", "plist", "entitlements":
                // XML和Plist文件通常以<?xml开头，但文件头是3c3f786d6c
                return hexString.hasPrefix("3c3f786d6c")
            default:
                logger.warning("未知文件扩展名，无法进行文件头验证: \(url.pathExtension)")
                return true // 对于未知类型，暂时允许通过
            }
        } catch {
            logger.error("文件头验证失败 \(url.lastPathComponent): \(error.localizedDescription)")
            return false
        }
    }
}