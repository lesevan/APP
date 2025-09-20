import CoreData
import OSLog
extension Storage {
	func getUuidDirectory(for app: AppInfoPresentable) -> URL? {
		// 提取需要的值到局部变量，避免在闭包中捕获app
		let appName = app.name
		let uuid = app.uuid
		let isSigned = app.isSigned
		
		guard let uuid = uuid else { 
			Task { @MainActor in
				Logger.misc.error("getUuidDirectory: UUID为空，应用: \(appName ?? "未知")")
			}
			return nil 
		}
		
		Task { @MainActor in
			Logger.misc.info("getUuidDirectory: UUID: \(uuid), isSigned: \(isSigned)")
		}
		
		let directory = isSigned
		? FileManager.default.signed(uuid)
		: FileManager.default.unsigned(uuid)
		
		Task { @MainActor in
			Logger.misc.info("getUuidDirectory: 目录路径: \(directory.path)")
		}
		
		return directory
	}
	
	func getAppDirectory(for app: AppInfoPresentable) -> URL? {
		// 提取需要的值到局部变量，避免在闭包中捕获app
		let appName = app.name
		
		guard let url = getUuidDirectory(for: app) else { 
			Task { @MainActor in
				Logger.misc.error("getAppDirectory: UUID目录为空，应用: \(appName ?? "未知")")
			}
			return nil 
		}
		
		Task { @MainActor in
			Logger.misc.info("getAppDirectory: UUID目录: \(url.path)")
		}
		
		if !FileManager.default.fileExists(atPath: url.path) {
			Task { @MainActor in
				Logger.misc.error("getAppDirectory: UUID目录不存在: \(url.path)")
			}
			return nil
		}
		
		if let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
			Task { @MainActor in
				Logger.misc.info("getAppDirectory: UUID目录内容: \(contents.map { $0.lastPathComponent })")
			}
		}
		
		let result = FileManager.default.getPath(in: url, for: "app")
		if result == nil {
			Task { @MainActor in
				Logger.misc.error("getAppDirectory: 在UUID目录中未找到.app文件")
			}
		} else {
			Task { @MainActor in
				Logger.misc.info("getAppDirectory: 找到.app文件: \(result!.path)")
			}
		}
		
		return result
	}
	
	@MainActor
	func deleteApp(for app: AppInfoPresentable) {
		Task { @MainActor in
			CrashProtection.shared.safeExecuteInAutoreleasePool({
				if let url = getUuidDirectory(for: app) {
					try? FileManager.default.removeItem(at: url)
				}
				if let object = app as? NSManagedObject {
					context.delete(object)
				}
				saveContext()
			}, fallback: (), operationName: "Delete app")
		}
	}
	
	func getCertificate(from app: AppInfoPresentable) -> CertificatePair? {
		if let signed = app as? Signed {
			return signed.certificate
		}
		return nil
	}
}

struct AnyApp: Identifiable {
	let base: AppInfoPresentable
	var archive: Bool = false
	
	var id: String {
		base.uuid ?? UUID().uuidString
	}
}

protocol AppInfoPresentable {
	var name: String? { get }
	var version: String? { get }
	var identifier: String? { get }
	var date: Date? { get }
	var icon: String? { get }
	var uuid: String? { get }
	var isSigned: Bool { get }
}

extension Signed: AppInfoPresentable {
	var isSigned: Bool { true }
}

extension Imported: AppInfoPresentable {
	var isSigned: Bool { false }
}
