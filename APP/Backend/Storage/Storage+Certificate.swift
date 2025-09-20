import CoreData
import UIKit.UIImpactFeedbackGenerator
import ZsignSwift
extension Storage {
	func addCertificate(
		uuid: String,
		password: String? = nil,
		nickname: String? = nil,
		ppq: Bool = false,
		expiration: Date,
		completion: @escaping (Error?) -> Void
	) {
		let generator = UIImpactFeedbackGenerator(style: .light)
		
		let new = CertificatePair(context: context)
		new.uuid = uuid
		new.date = Date()
		new.password = password
		new.ppQCheck = ppq
		new.expiration = expiration
		new.nickname = nickname
		Storage.shared.revokagedCertificate(for: new)
		saveContext()
		generator.impactOccurred()
		completion(nil)
	}
	
	@MainActor
	func deleteCertificate(for cert: CertificatePair) {
		if let url = getUuidDirectory(for: cert) {
			try? FileManager.default.removeItem(at: url)
		}
		context.delete(cert)
		saveContext()
	}
	
	func getCertificate(for index: Int) -> CertificatePair? {
		let fetchRequest: NSFetchRequest<CertificatePair> = CertificatePair.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]

		guard
			let results = try? context.fetch(fetchRequest),
			index >= 0 && index < results.count
		else {
			return nil
		}
		
		return results[index]
	}
	
	nonisolated func revokagedCertificate(for cert: CertificatePair) {
		guard !cert.revoked else { return }
		
		// 提取所有需要的值到局部变量，避免在闭包中捕获cert对象
		let certUUID = cert.uuid ?? ""
		let provisionPath = Storage.shared.getFile(.provision, from: cert)?.path ?? ""
		let p12Path = Storage.shared.getFile(.certificate, from: cert)?.path ?? ""
		let p12Password = cert.password ?? ""
		
		Zsign.checkRevokage(
			provisionPath: provisionPath,
			p12Path: p12Path,
			p12Password: p12Password
		) { (status, _, _) in
			if status == 1 {
				DispatchQueue.main.async {
					// 通过UUID重新获取证书对象，避免数据竞争
					if let certToUpdate = Storage.shared.getCertificateByUUID(certUUID) {
						certToUpdate.revoked = true
						Storage.shared.saveContext()
					}
				}
			}
		}
	}
	
	enum FileRequest: String {
		case certificate = "p12"
		case provision = "mobileprovision"
	}
	
	func getFile(_ type: FileRequest, from cert: CertificatePair) -> URL? {
		guard let url = getUuidDirectory(for: cert) else {
			return nil
		}
		
		return FileManager.default.getPath(in: url, for: type.rawValue)
	}
	
	func getProvisionFileDecoded(for cert: CertificatePair) -> Certificate? {
		guard let url = getFile(.provision, from: cert) else {
			return nil
		}
		
		let read = CertificateReader(url)
		return read.decoded
	}
	
	func getUuidDirectory(for cert: CertificatePair) -> URL? {
		guard let uuid = cert.uuid else {
			return nil
		}
		
		return FileManager.default.certificates(uuid)
	}
	
	func getAllCertificates() -> [CertificatePair] {
		let fetchRequest: NSFetchRequest<CertificatePair> = CertificatePair.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
		return (try? context.fetch(fetchRequest)) ?? []
	}
	
	func getCertificateByUUID(_ uuid: String) -> CertificatePair? {
		let fetchRequest: NSFetchRequest<CertificatePair> = CertificatePair.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid)
		fetchRequest.fetchLimit = 1
		return (try? context.fetch(fetchRequest))?.first
	}
}
