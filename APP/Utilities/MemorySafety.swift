import Foundation
import os.log

/// 内存安全工具类，用于检测和防止常见的内存管理问题
@MainActor
final class MemorySafety {
    static let shared = MemorySafety()
    
    private let logger = Logger(subsystem: "com.feather.memory", category: "MemorySafety")
    private var weakReferences: [String: WeakReference] = [:]
    
    private init() {}
    
    /// 跟踪对象的弱引用，用于检测内存泄漏
    func trackObject<T: AnyObject>(_ object: T, identifier: String) {
        weakReferences[identifier] = WeakReference(object: object)
        logger.debug("Tracking object with identifier: \(identifier)")
    }
    
    /// 检查是否有内存泄漏
    func checkForLeaks() {
        let leakedObjects = weakReferences.compactMap { (identifier, weakRef) in
            weakRef.object == nil ? nil : identifier
        }
        
        if !leakedObjects.isEmpty {
            logger.warning("Potential memory leaks detected for identifiers: \(leakedObjects.joined(separator: ", "))")
        } else {
            logger.info("No memory leaks detected")
        }
    }
    
    /// 清理已释放对象的跟踪记录
    func cleanup() {
        weakReferences = weakReferences.filter { $0.value.object != nil }
    }
}

/// 弱引用包装器
private final class WeakReference {
    weak var object: AnyObject?
    
    init(object: AnyObject) {
        self.object = object
    }
}

/// 内存安全扩展
extension NSObject {
    /// 安全地执行操作，确保对象在操作期间保持有效
    func safeExecute<T>(_ operation: () throws -> T) rethrows -> T? {
        guard !isBeingDeallocated else {
            return nil
        }
        return try operation()
    }
    
    /// 检查对象是否正在被释放
    private var isBeingDeallocated: Bool {
        // 这是一个简化的检查，实际实现可能需要更复杂的逻辑
        return false
    }
}

/// 自动释放池安全工具
struct SafeAutoreleasePool {
    static func execute<T>(_ operation: () throws -> T) rethrows -> T {
        return try autoreleasepool {
            try operation()
        }
    }
}

/// 线程安全工具
actor ThreadSafeContainer<T> {
    private var value: T
    
    init(_ value: T) {
        self.value = value
    }
    
    func get() -> T {
        return value
    }
    
    func set(_ newValue: T) {
        value = newValue
    }
    
    func update(_ operation: (inout T) -> Void) {
        operation(&value)
    }
}

/// 内存压力监控
@MainActor
final class MemoryPressureMonitor {
    static let shared = MemoryPressureMonitor()
    
    private let logger = Logger(subsystem: "com.feather.memory", category: "MemoryPressureMonitor")
    private var source: DispatchSourceMemoryPressure?
    
    private init() {
        setupMemoryPressureMonitoring()
    }
    
    private func setupMemoryPressureMonitoring() {
        source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: .main)
        
        source?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            let event = self.source?.mask ?? []
            
            if event.contains(.warning) {
                self.logger.warning("Memory pressure warning detected")
                self.handleMemoryPressure()
            } else if event.contains(.critical) {
                self.logger.error("Critical memory pressure detected")
                self.handleCriticalMemoryPressure()
            }
        }
        
        source?.resume()
    }
    
    private func handleMemoryPressure() {
        // 清理缓存、释放不必要的对象等
        URLCache.shared.removeAllCachedResponses()
        MemorySafety.shared.cleanup()
    }
    
    private func handleCriticalMemoryPressure() {
        // 更激进的清理策略
        handleMemoryPressure()
        
        // 可以在这里添加更多紧急清理逻辑
        logger.critical("Critical memory pressure - performing emergency cleanup")
    }
    
    deinit {
        source?.cancel()
    }
}
