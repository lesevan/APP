import Foundation.NSURL
import UIKit.UIImage
import Zsign
import AltSourceKit
import OSLog

enum FR {
	static func handlePackageFile(
		_ ipa: URL,
		download: Download? = nil,
		completion: @escaping @Sendable (Error?) -> Void
	) {
		Task { @MainActor in
			Logger.misc.info("FR.handlePackageFile 调用: \(ipa.path)")
		}
		Task.detached {
			let handler = AppFileHandler(file: ipa, download: download)
			
				do {
					Task { @MainActor in
						Logger.misc.info("开始IPA处理流程")
					}
					try await handler.performCopy()
					Task { @MainActor in
						Logger.misc.info("复制完成")
					}
				try await handler.extract()
				Task { @MainActor in
					Logger.misc.info("解压完成")
				}
				try await handler.move()
				Task { @MainActor in
					Logger.misc.info("移动完成")
				}
				try await handler.addToDatabase()
				Task { @MainActor in
					Logger.misc.info("添加到数据库完成")
				}
				try? await handler.clean()
				Task { @MainActor in
					Logger.misc.info("IPA处理成功完成")
				}
				await MainActor.run {
					completion(nil)
				}
			} catch {
				Task { @MainActor in
					Logger.misc.error("IPA处理失败: \(error.localizedDescription)")
				}
				try? await handler.clean()
				await MainActor.run {
					completion(error)
				}
			}
		}
	}
	
	static func signPackageFile(
		_ app: AppInfoPresentable,
		using options: Options,
		icon: UIImage?,
		certificate: CertificatePair?,
		completion: @escaping (Error?) -> Void
	) {
		Task {
			let handler = SigningHandler(app: app, options: options)
			handler.appCertificate = certificate
			handler.appIcon = icon
			
			do {
				try await handler.copy()
				try await handler.modify()
				try? await handler.clean()
				completion(nil)
			} catch {
				try? await handler.clean()
				completion(error)
			}
		}
	}
	
	static func handleCertificateFiles(
		p12URL: URL,
		provisionURL: URL,
		p12Password: String,
		certificateName: String = "",
		completion: @escaping @Sendable (Error?) -> Void
	) {
		Task.detached {
			do {
				let handler = CertificateFileHandler(
					key: p12URL,
					provision: provisionURL,
					password: p12Password,
					nickname: certificateName.isEmpty ? nil : certificateName
				)
				
				print("开始处理证书文件: \(p12URL.lastPathComponent)")
				try await handler.copy()
				print("证书文件复制完成，开始添加到数据库")
				try await handler.addToDatabase()
				print("证书导入成功")
				
				await MainActor.run {
					completion(nil)
				}
			} catch {
				print("证书导入失败: \(error.localizedDescription)")
				await MainActor.run {
					completion(error)
				}
			}
		}
	}
	
	static func checkPasswordForCertificate(
		for key: URL,
		with password: String,
		using provision: URL
	) -> Bool {
		defer {
			password_check_fix_WHAT_THE_FUCK_free(provision.path)
		}
		
		password_check_fix_WHAT_THE_FUCK(provision.path)
		
		if (!p12_password_check(key.path, password)) {
			return false
		}
		
		return true
	}
	
	static func movePairing(_ url: URL) {
		let fileManager = FileManager.default
		let dest = URL.documentsDirectory.appendingPathComponent("pairingFile.plist")
		
		try? fileManager.removeFileIfNeeded(at: dest)
		
		try? fileManager.copyItem(at: url, to: dest)
		
		Task { @MainActor in
			HeartbeatManager.shared.start(true)
		}
	}
	
	static func downloadSSLCertificates(
		from urlString: String,
		completion: @escaping @Sendable (Bool) -> Void
	) {
		Task { @MainActor in
			let generator = UINotificationFeedbackGenerator()
			generator.prepare()
			
			NBFetchService().fetch(from: urlString) { (result: Result<ServerView.ServerPackModel, Error>) in
				switch result {
				case .success(let pack):
					do {
						try FileManager.forceWrite(content: pack.key, to: "server.pem")
						try FileManager.forceWrite(content: pack.cert, to: "server.crt")
						try FileManager.forceWrite(content: pack.info.domains.commonName, to: "commonName.txt")
						Task { @MainActor in
							generator.notificationOccurred(.success)
						}
						completion(true)
					} catch {
						completion(false)
					}
				case .failure(_):
					completion(false)
				}
			}
		}
	}
	
	
	static func exportCertificateAndOpenUrl(using template: String) {
		Task { @MainActor in
			@MainActor
			func performExport(for certificate: CertificatePair) {
				guard
					let certificateKeyFile = Storage.shared.getFile(.certificate, from: certificate),
					let certificateKeyFileData = try? Data(contentsOf: certificateKeyFile)
				else {
					return
				}
				
				let base64encodedCert = certificateKeyFileData.base64EncodedString()
				
				var allowedQueryParamAndKey = NSCharacterSet.urlQueryAllowed
				allowedQueryParamAndKey.remove(charactersIn: ";/?:@&=+$, ")
				
				guard let encodedCert = base64encodedCert.addingPercentEncoding(withAllowedCharacters: allowedQueryParamAndKey) else {
					return
				}
				
				let urlStr = template
					.replacingOccurrences(of: "$(BASE64_CERT)", with: encodedCert)
					.replacingOccurrences(of: "$(PASSWORD)", with: certificate.password ?? "")
				
				guard let callbackUrl = URL(string: urlStr) else {
					return
				}
				
				UIApplication.shared.open(callbackUrl)
			}
			
			let certificates = Storage.shared.getAllCertificates()
			guard !certificates.isEmpty else { return }
			
			var selectionActions: [UIAlertAction] = []
			
			for cert in certificates {
				var title: String
				let decoded = Storage.shared.getProvisionFileDecoded(for: cert)
				
				title = cert.nickname ?? decoded?.Name ?? "未知"
				
				if let getTaskAllow = decoded?.Entitlements?["get-task-allow"]?.value as? Bool, getTaskAllow == true {
					title = "🐞 \(title)"
				}
				
				let selectAction = UIAlertAction(title: title, style: .default) { _ in
					performExport(for: cert)
				}
				selectionActions.append(selectAction)
			}
			
			UIAlertController.showAlertWithCancel(
				title: "导出证书",
				message: "您想要将证书导出到外部应用吗？该应用将能够使用您的证书对应用进行签名。",
				style: .alert,
				actions: selectionActions
			)
		}
	}
}
