import Foundation
import Combine
import UIKit.UIImpactFeedbackGenerator
import OSLog

@MainActor
class Download: Identifiable, ObservableObject {
	@Published var progress: Double = 0.0
	@Published var bytesDownloaded: Int64 = 0
	@Published var totalBytes: Int64 = 0
	@Published var unpackageProgress: Double = 0.0
	
	var overallProgress: Double {
		onlyArchiving
		? unpackageProgress
		: (0.3 * unpackageProgress) + (0.7 * progress)
	}
	
    var task: URLSessionDownloadTask?
    var resumeData: Data?
	
	let id: String
	let url: URL
	let fileName: String
	let onlyArchiving: Bool
    
    init(
		id: String,
		url: URL,
		onlyArchiving: Bool = false
	) {
		self.id = id
        self.url = url
		self.onlyArchiving = onlyArchiving
        self.fileName = url.lastPathComponent
    }
	
	deinit {
		// 确保在对象释放时取消任务
		task?.cancel()
	}
}

class DownloadManager: NSObject, ObservableObject, @unchecked Sendable {
	static let shared = DownloadManager()
	
    @Published var downloads: [Download] = []
	private let downloadsQueue = DispatchQueue(label: "com.feather.downloads", qos: .userInitiated)
	private let logger = Logger(subsystem: "com.feather.downloads", category: "DownloadManager")
	
	var manualDownloads: [Download] {
		downloads.filter { isManualDownload($0.id) }
	}
	
    private var _session: URLSession!
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        _session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    @MainActor
    func startDownload(
		from url: URL,
		id: String = UUID().uuidString
	) -> Download {
        if let existingDownload = downloads.first(where: { $0.url == url }) {
            resumeDownload(existingDownload)
            return existingDownload
        }
        
		let download = Download(id: id, url: url)
        
        let task = _session.downloadTask(with: url)
        download.task = task
        task.resume()
        
        downloads.append(download)
        logger.info("Started download for URL: \(url.absoluteString)")
        return download
    }
	
    @MainActor
	func startArchive(
		from url: URL,
		id: String = UUID().uuidString
	) -> Download {
		let download = Download(id: id, url: url, onlyArchiving: true)
		downloads.append(download)
		logger.info("Started archive for URL: \(url.absoluteString)")
		return download
	}
    
    @MainActor
    func resumeDownload(_ download: Download) {
        if let resumeData = download.resumeData {
            let task = _session.downloadTask(withResumeData: resumeData)
            download.task = task
            task.resume()
            logger.info("Resumed download with resume data for ID: \(download.id)")
        } else if let url = download.task?.originalRequest?.url {
            let task = _session.downloadTask(with: url)
            download.task = task
            task.resume()
            logger.info("Resumed download for URL: \(url.absoluteString)")
        }
    }
    
    @MainActor
    func cancelDownload(_ download: Download) {
        download.task?.cancel()
        
        if let index = downloads.firstIndex(where: { $0.id == download.id }) {
            downloads.remove(at: index)
            logger.info("Cancelled and removed download for ID: \(download.id)")
        }
    }
    
	func isManualDownload(_ string: String) -> Bool {
		return string.contains("FeatherManualDownload")
	}
	
    @MainActor
	func getDownload(by id: String) -> Download? {
		return downloads.first(where: { $0.id == id })
	}
	
    @MainActor
	func getDownloadIndex(by id: String) -> Int? {
		return downloads.firstIndex(where: { $0.id == id })
	}
	
    @MainActor
	func getDownloadTask(by task: URLSessionDownloadTask) -> Download? {
		return downloads.first(where: { $0.task == task })
	}
}

extension DownloadManager: URLSessionDownloadDelegate {
	
	func handlePachageFile(url: URL, dl: Download) throws {
		logger.info("DownloadManager.handlePachageFile 调用: \(url.path)")
		FR.handlePackageFile(url, download: dl) { [weak self] err in
			Task { @MainActor in
				guard let self = self else { return }
				
				if let err = err {
					self.logger.error("DownloadManager IPA处理失败: \(err.localizedDescription)")
					let generator = UINotificationFeedbackGenerator()
					generator.notificationOccurred(.error)
				} else {
					self.logger.info("DownloadManager IPA处理成功完成")
				}
				
				if let index = self.getDownloadIndex(by: dl.id) {
					self.downloads.remove(at: index)
				}
			}
		}
	}
	
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		Task { @MainActor in
			guard let download = getDownloadTask(by: downloadTask) else { return }
			
			let tempDirectory = FileManager.default.temporaryDirectory
			let customTempDir = tempDirectory.appendingPathComponent("FeatherDownloads", isDirectory: true)
			
			do {
				try FileManager.default.createDirectoryIfNeeded(at: customTempDir)
				
				let suggestedFileName = downloadTask.response?.suggestedFilename ?? download.fileName
				let destinationURL = customTempDir.appendingPathComponent(suggestedFileName)
				
				try FileManager.default.removeFileIfNeeded(at: destinationURL)
				try FileManager.default.moveItem(at: location, to: destinationURL)
				
				try handlePachageFile(url: destinationURL, dl: download)
			} catch {
				logger.error("处理下载文件时出错: \(error.localizedDescription)")
			}
		}
	}
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task { @MainActor in
            guard let download = getDownloadTask(by: downloadTask) else { return }
            
            download.progress = totalBytesExpectedToWrite > 0
			? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
			: 0
            download.bytesDownloaded = totalBytesWritten
            download.totalBytes = totalBytesExpectedToWrite
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let _ = error,
			let downloadTask = task as? URLSessionDownloadTask else {
			return
		}
		
		Task { @MainActor in
			guard let download = getDownloadTask(by: downloadTask) else { return }
			
			if let index = getDownloadIndex(by: download.id) {
				downloads.remove(at: index)
				logger.info("Removed failed download for ID: \(download.id)")
			}
		}
    }
}
