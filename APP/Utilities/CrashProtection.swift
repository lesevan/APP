import Foundation
import CoreData
import os.log

/// 崩溃防护工具类，用于防止常见的崩溃场景
@MainActor
final class CrashProtection {
    static let shared = CrashProtection()
    
    private let logger = Logger(subsystem: "com.feather.crash", category: "CrashProtection")
    
    private init() {}
    
    /// 安全地执行可能崩溃的操作
    func safeExecute<T>(
        _ operation: () throws -> T,
        fallback: T,
        operationName: String = "Unknown operation"
    ) -> T {
        do {
            return try operation()
        } catch {
            logger.error("Operation '\(operationName)' failed: \(error.localizedDescription)")
            return fallback
        }
    }
    
    /// 安全地执行可能崩溃的异步操作
    func safeExecuteAsync<T>(
        _ operation: () async throws -> T,
        fallback: T,
        operationName: String = "Unknown async operation"
    ) async -> T {
        do {
            return try await operation()
        } catch {
            logger.error("Async operation '\(operationName)' failed: \(error.localizedDescription)")
            return fallback
        }
    }
    
    /// 验证对象是否有效
    func validateObject<T: AnyObject>(_ object: T?, operationName: String = "Object validation") -> Bool {
        guard let object = object else {
            logger.warning("\(operationName): Object is nil")
            return false
        }
        
        // 检查对象是否是NSObject类型
        guard let nsObject = object as? NSObject else {
            logger.warning("\(operationName): Object is not NSObject")
            return false
        }
        
        // 检查对象是否响应基本方法
        guard nsObject.responds(to: #selector(NSObject.description)) else {
            logger.warning("\(operationName): Object does not respond to description")
            return false
        }
        
        return true
    }
    
    /// 安全地访问数组元素
    func safeArrayAccess<T>(_ array: [T], index: Int, operationName: String = "Array access") -> T? {
        guard index >= 0 && index < array.count else {
            logger.warning("\(operationName): Index \(index) out of bounds for array of size \(array.count)")
            return nil
        }
        return array[index]
    }
    
    /// 安全地访问字典值
    func safeDictionaryAccess<K, V>(_ dictionary: [K: V], key: K, operationName: String = "Dictionary access") -> V? {
        guard let value = dictionary[key] else {
            logger.warning("\(operationName): Key not found in dictionary")
            return nil
        }
        return value
    }
}

/// 自动释放池安全执行
extension CrashProtection {
    /// 在自动释放池中安全执行操作
    func safeExecuteInAutoreleasePool<T>(
        _ operation: () throws -> T,
        fallback: T,
        operationName: String = "Autorelease pool operation"
    ) -> T {
        return autoreleasepool {
            safeExecute(operation, fallback: fallback, operationName: operationName)
        }
    }
}

/// 内存访问安全工具
extension CrashProtection {
    /// 安全地访问可能为nil的指针
    func safePointerAccess<T>(
        _ pointer: UnsafePointer<T>?,
        operationName: String = "Pointer access"
    ) -> T? {
        guard let pointer = pointer else {
            logger.warning("\(operationName): Pointer is nil")
            return nil
        }
        
        // 检查指针是否有效（基本检查）
        return pointer.pointee
    }
}

/// 网络请求安全工具
extension CrashProtection {
    /// 安全地处理网络请求
    func safeNetworkRequest(
        _ request: URLRequest,
        session: URLSession = .shared,
        operationName: String = "Network request"
    ) async -> (data: Data?, response: URLResponse?, error: Error?) {
        do {
            let (data, response) = try await session.data(for: request)
            return (data, response, nil)
        } catch {
            logger.error("\(operationName) failed: \(error.localizedDescription)")
            return (nil, nil, error)
        }
    }
}

/// Core Data安全工具
extension CrashProtection {
    /// 安全地执行Core Data操作
    func safeCoreDataOperation<T>(
        _ operation: () throws -> T,
        context: NSManagedObjectContext,
        operationName: String = "Core Data operation"
    ) -> T? {
        do {
            return try operation()
        } catch {
            logger.error("\(operationName) failed: \(error.localizedDescription)")
            context.rollback()
            return nil
        }
    }
    
    /// 安全地保存Core Data上下文
    func safeSaveContext(
        _ context: NSManagedObjectContext,
        operationName: String = "Core Data save"
    ) -> Bool {
        guard context.hasChanges else {
            return true
        }
        
        do {
            try context.save()
            logger.info("\(operationName) succeeded")
            return true
        } catch {
            logger.error("\(operationName) failed: \(error.localizedDescription)")
            context.rollback()
            return false
        }
    }
}
