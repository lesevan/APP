//
//  StoreClient.swift
//  APP
//
//  Created by pxx917144686 on 2025/08/20.
//
import Foundation
import Security
import Network
// 从 iTunesAPI 导入共享类型
// DeviceFamily 和 iTunesSearchResult 定义在 iTunesAPI.swift 中
// MARK: - 类型别名和导入
// 移除自引用类型别名 - 这些类型已在各自文件中可用
// MARK: - 本地账户定义
// 用于 StoreClient 兼容性的本地账户定义
struct LocalAccount {
    let firstName: String
    let lastName: String
    let directoryServicesIdentifier: String
    let passwordToken: String
    let name: String
    let email: String
    let dsPersonId: String
    let cookies: [String]
    let countryCode: String
    // 方便的初始化方法，匹配 Apple.Account 接口
    init(firstName: String, lastName: String, directoryServicesIdentifier: String, passwordToken: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.directoryServicesIdentifier = directoryServicesIdentifier
        self.passwordToken = passwordToken
        self.name = "\(firstName) \(lastName)"
        self.email = ""
        self.dsPersonId = directoryServicesIdentifier
        self.cookies = []
        self.countryCode = "US"
    }
    // 完整的初始化方法
    init(name: String, email: String, firstName: String, lastName: String, passwordToken: String, directoryServicesIdentifier: String, dsPersonId: String, cookies: [String], countryCode: String) {
        self.name = name
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.passwordToken = passwordToken
        self.directoryServicesIdentifier = directoryServicesIdentifier
        self.dsPersonId = dsPersonId
        self.cookies = cookies
        self.countryCode = countryCode
    }
}
/// iTunes 搜索结果结构（使用 iTunesAPI.swift 中的共享定义）
// 注意：DeviceFamily 和 iTunesSearchResult 定义在 iTunesAPI.swift 中以避免重复
/// StoreClient 的扩展 iTunes 搜索结果
struct ExtendedSearchResult: Codable {
    let trackId: Int?
    let trackName: String?
    let artistName: String?
    let bundleId: String?
    let version: String?
    let formattedPrice: String?
    let price: Double?
    let currency: String?
    let trackViewUrl: String?
    let artworkUrl60: String?
    let artworkUrl100: String?
    let artworkUrl512: String?
    let screenshotUrls: [String]?
    let ipadScreenshotUrls: [String]?
    let description: String?
    let releaseNotes: String?
    let sellerName: String?
    let genres: [String]?
    let primaryGenreName: String?
    let contentAdvisoryRating: String?
    let averageUserRating: Double?
    let userRatingCount: Int?
    let fileSizeBytes: String?
    let minimumOsVersion: String?
    let currentVersionReleaseDate: String?
    let releaseDate: String?
    let isGameCenterEnabled: Bool?
    let supportedDevices: [String]?
    let languageCodesISO2A: [String]?
    let advisories: [String]?
    let features: [String]?
}
// 注意：StoreError 定义在 StoreRequest.swift 中以避免类型歧义
// MARK: - StoreRequest 引用
// StoreRequest 定义在 StoreRequest.swift 中
// Account 定义在其他文件中以避免重复
// AuthenticationManager 定义在 AuthenticationManager.swift 中以避免重复
// MARK: - 商店客户端实现
class StoreClient {
    static let shared = StoreClient()
    private init() {}
    func searchApps(
        query: String,
        limit: Int = 50,
        country: String = "US",
        deviceType: String = "iPhone"
    ) async -> Result<[ExtendedSearchResult], Error> {
        // 模拟搜索结果
        let mockResult = ExtendedSearchResult(
            trackId: 123,
            trackName: query,
            artistName: "Developer",
            bundleId: "com.example.\(query.lowercased())",
            version: "1.0",
            formattedPrice: "Free",
            price: nil,
            currency: nil,
            trackViewUrl: nil,
            artworkUrl60: nil,
            artworkUrl100: nil,
            artworkUrl512: nil,
            screenshotUrls: nil,
            ipadScreenshotUrls: nil,
            description: nil,
            releaseNotes: nil,
            sellerName: nil,
            genres: nil,
            primaryGenreName: nil,
            contentAdvisoryRating: nil,
            averageUserRating: nil,
            userRatingCount: nil,
            fileSizeBytes: nil,
            minimumOsVersion: nil,
            currentVersionReleaseDate: nil,
            releaseDate: nil,
            isGameCenterEnabled: nil,
            supportedDevices: nil,
            languageCodesISO2A: nil,
            advisories: nil,
            features: nil
        )
        return .success([mockResult])
    }
    func lookupApp(
        bundleId: String,
        country: String = "US",
        deviceType: String = "iPhone"
    ) async -> Result<ExtendedSearchResult?, Error> {
        // 模拟应用查找
        let mockResult = ExtendedSearchResult(
            trackId: 456,
            trackName: "App",
            artistName: "Developer",
            bundleId: bundleId,
            version: "1.0",
            formattedPrice: "Free",
            price: nil,
            currency: nil,
            trackViewUrl: nil,
            artworkUrl60: nil,
            artworkUrl100: nil,
            artworkUrl512: nil,
            screenshotUrls: nil,
            ipadScreenshotUrls: nil,
            description: nil,
            releaseNotes: nil,
            sellerName: nil,
            genres: nil,
            primaryGenreName: nil,
            contentAdvisoryRating: nil,
            averageUserRating: nil,
            userRatingCount: nil,
            fileSizeBytes: nil,
            minimumOsVersion: nil,
            currentVersionReleaseDate: nil,
            releaseDate: nil,
            isGameCenterEnabled: nil,
            supportedDevices: nil,
            languageCodesISO2A: nil,
            advisories: nil,
            features: nil
        )
        return .success(mockResult)
    }
    func getTrackId(
        bundleIdentifier: String,
        countryCode: String = "US",
        deviceFamily: String = "phone"
    ) async throws -> Int? {
        // 模拟曲目 ID 查找
        return 789
    }
}
// SignatureClient 定义在 SignatureClient.swift 中以避免重复
    func sign() throws {
        // 模拟签名
    }
    func save(to path: String) throws {
        // 模拟保存
    }
// MARK: - 商店响应模型（从 StoreAPI.swift 移动过来）
struct LocalStoreAuthResponse: Codable {
    let accountInfo: AccountInfo
    let passwordToken: String
    let dsPersonId: String
    let pings: [String]?
    struct AccountInfo: Codable {
        let appleId: String
        let address: Address
        let dsPersonId: String
        let countryCode: String?
        let storeFront: String?
        struct Address: Codable {
            let firstName: String
            let lastName: String
        }
    }
}
struct StoreFailureResponse: Codable {
    let failureType: String
    let customerMessage: String
    let pings: [String]?
}
// MARK: - 商店响应模型
// 注意：StoreDownloadResponse 和 StorePurchaseResponse 定义在 StoreRequest.swift 中以避免类型歧义
// MARK: - 商店数据模型（从 DownloadManager.swift 统一过来）
struct LocalStoreItem: Codable {
    let url: String
    let md5: String
    let sinfs: [SinfInfo]
    let metadata: AppMetadata
}
struct LocalAppMetadata: Codable {
    let bundleId: String
    let bundleDisplayName: String
    let bundleShortVersionString: String
    let softwareVersionExternalIdentifier: String
    let softwareVersionExternalIdentifiers: [Int]?
    enum CodingKeys: String, CodingKey {
        case bundleId = "softwareVersionBundleId"
        case bundleDisplayName
        case bundleShortVersionString
        case softwareVersionExternalIdentifier
        case softwareVersionExternalIdentifiers
    }
}
struct LocalSinfInfo: Codable {
    let id: Int
    let sinf: String
}
// MARK: - 商店端点
struct StoreEndpoint {
    static func authenticate(guid: String) -> String {
        return "https://auth.itunes.apple.com/auth/v1/native/fast?guid=\(guid)"
    }
    static func download(guid: String) -> String {
        return "https://p25-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct?guid=\(guid)"
    }
    static let purchase = "https://buy.itunes.apple.com/WebObjects/MZBuy.woa/wa/buyProduct"
}
// MARK: - 账户信息
// Account 结构体移动到 AuthenticationManager.swift 中以避免重复
// MARK: - 应用版本信息
struct AppVersion: Codable, Identifiable {
    let id: UUID
    let versionString: String
    let versionId: String
    let isCurrent: Bool
    init(versionString: String, versionId: String, isCurrent: Bool) {
        self.id = UUID()
        self.versionString = versionString
        self.versionId = versionId
        self.isCurrent = isCurrent
    }
    var displayName: String {
        return isCurrent ? "\(versionString) (当前版本)" : versionString
    }
}
// MARK: - 下载进度信息
// 注意：DownloadProgress 定义在 DownloadManager.swift 中
// MARK: - 商店客户端扩展（延续之前的定义）
extension StoreClient {
    // MARK: - 身份验证（委托给 AuthenticationManager）
    /// 使用 Apple ID 进行身份验证
    func authenticate(email: String, password: String, mfaCode: String? = nil) async -> Result<Account, StoreError> {
        do {
            let account = try await AuthenticationManager.shared.authenticate(email: email, password: password, mfa: mfaCode)
            return .success(account)
        } catch let error as StoreError {
            return .failure(error)
        } catch {
            return .failure(StoreError.unknownError)
        }
    }
    /// 从保存的钥匙串凭据登录
    func loginFromKeychain() async -> Account? {
        return AuthenticationManager.shared.loadSavedAccount()
    }
    /// 撤销保存的凭据
    func revokeCredentials() -> Bool {
        return AuthenticationManager.shared.deleteSavedAccount()
    }
    // MARK: - 应用购买和下载
    /// 购买应用许可证
    func purchaseApp(
        trackId: String,
        account: Account,
        country: String = "US"
    ) async -> Result<StorePurchaseResponse, StoreError> {
        // 为会话设置 cookie
        setCookies(account.cookies)
        do {
            let result = try await StoreRequest.shared.purchase(
                appIdentifier: trackId,
                directoryServicesIdentifier: account.dsPersonId,
                passwordToken: account.passwordToken,
                countryCode: country
            )
            return .success(result)
        } catch {
            return .failure(.genericError)
        }
    }
    /// 获取可用的应用版本
    func getAppVersions(
        trackId: String,
        account: Account
    ) async -> Result<[AppVersion], StoreError> {
        // 为会话设置 cookie
        setCookies(account.cookies)
        do {
            // 优先尝试使用第三方 API 获取版本信息
            if let thirdPartyVersions = try await fetchVersionsFromThirdPartyAPI(appId: trackId) {
                print("[DEBUG] Successfully fetched versions from third-party API: \(thirdPartyVersions.count) versions")
                return .success(thirdPartyVersions)
            }
            print("[DEBUG] Third-party API failed or returned no data, falling back to Apple official API")
            // 如果第三方 API 失败，回退到 Apple 官方 API
            // 首先获取当前版本信息
            let result = try await StoreRequest.shared.download(
                appIdentifier: trackId,
                directoryServicesIdentifier: account.dsPersonId,
                appVersion: nil
            )
            // 检查 songList 是否为空，避免数组越界
            guard !result.songList.isEmpty else {
                return .failure(.invalidItem)
            }
            let item = result.songList[0]
            // 从元数据中提取版本信息
            var versions: [AppVersion] = []
            // 当前版本
            let currentVersion = AppVersion(
                versionString: item.metadata.bundleShortVersionString,
                versionId: item.metadata.softwareVersionExternalIdentifier,
                isCurrent: true
            )
            versions.append(currentVersion)
            // 如果有历史版本则添加
            if let historicalVersionIds = item.metadata.softwareVersionExternalIdentifiers {
                print("[DEBUG] Found \(historicalVersionIds.count) historical version IDs")
                print("[DEBUG] Current version ID: \(item.metadata.softwareVersionExternalIdentifier)")
                print("[DEBUG] First 10 historical IDs: \(Array(historicalVersionIds.prefix(10)))")
                // 为历史版本创建 AppVersion 对象
                // 注意：我们只有历史版本的 ID，没有版本字符串
                // 我们将反转数组，以便先显示较新的版本（不包括当前版本）
                let reversedIds = Array(historicalVersionIds.reversed())
                var versionCounter = 1
                for versionId in reversedIds {
                    let versionIdString = String(versionId)
                    // 跳过当前版本（已经添加）
                    if versionIdString != item.metadata.softwareVersionExternalIdentifier {
                        let historicalVersion = AppVersion(
                            versionString: "历史版本 \(versionCounter)",
                            versionId: versionIdString,
                            isCurrent: false
                        )
                        versions.append(historicalVersion)
                        print("[DEBUG] Added historical version: \(versionCounter), ID: \(versionIdString)")
                        versionCounter += 1
                        // 限制版本数量，避免 UI 杂乱
                        if versionCounter > 20 {
                            print("[DEBUG] Reached version limit, stopping at \(versionCounter-1) versions")
                            break
                        }
                    }
                }
                print("[DEBUG] Successfully processed \(versionCounter-1) historical versions")
            } else {
                print("[DEBUG] No historical version IDs found in metadata")
            }
            print("[DEBUG] Total versions found: \(versions.count)")
            return .success(versions)
        } catch {
            print("[DEBUG] Error in getAppVersions: \(error)")
            return .failure(.genericError)
        }
    }
    // 使用第三方 API 获取 APP 版本信息
    private func fetchVersionsFromThirdPartyAPI(appId: String) async throws -> [AppVersion]? {
        let apiUrl = "https://api.timbrd.com/apple/app-version/index.php?id=\(appId)"
        guard let url = URL(string: apiUrl) else {
            print("[DEBUG] Invalid third-party API URL")
            return nil
        }
        do {
            // 设置请求超时时间为 10 秒
            let request = URLRequest(url: url, timeoutInterval: 10.0)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("[DEBUG] Third-party API returned non-200 status code")
                return nil
            }
            // 解析 JSON 响应
            let decoder = JSONDecoder()
            let versionData = try decoder.decode([AppVersionInfo].self, from: data)
            if versionData.isEmpty {
                print("[DEBUG] Third-party API returned empty version list")
                return nil
            }
            // 转换为 AppVersion 对象，按照版本发布时间倒序排序（最新的版本在前）
            let versions = versionData.sorted { version1, version2 -> Bool in
                // 尝试将 created_at 字符串转换为 Date 进行比较
                if let date1 = parseDate(version1.created_at), let date2 = parseDate(version2.created_at) {
                    return date1 > date2
                }
                // 如果日期解析失败，按照 bundle_version 字符串进行比较
                return compareVersionStrings(version1.bundle_version, version2.bundle_version) > 0
            }.map { versionInfo -> AppVersion in
                // 判断是否为当前版本（这里简单假设第一个就是最新版本）
                let isCurrent = versionInfo.bundle_version == versionData.first?.bundle_version
                return AppVersion(
                    versionString: versionInfo.bundle_version,
                    versionId: String(versionInfo.external_identifier),
                    isCurrent: isCurrent
                )
            }
            return versions
        } catch {    
            print("[DEBUG] Error fetching from third-party API: \(error)")
            return nil
        }
    }
    // 用于解析第三方 API 返回的版本信息
    private struct AppVersionInfo: Codable {
        let bundle_version: String
        let external_identifier: Int
        let created_at: String
    }
    // 解析日期字符串
    private func parseDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: dateString)
    }
    // 比较版本字符串（简单实现，处理主要版本号格式）
    private func compareVersionStrings(_ v1: String, _ v2: String) -> Int {
        let components1 = v1.split(separator: ".").compactMap { Int($0) }
        let components2 = v2.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(components1.count, components2.count) {
            let num1 = i < components1.count ? components1[i] : 0
            let num2 = i < components2.count ? components2[i] : 0
            if num1 > num2 {
                return 1
            } else if num1 < num2 {
                return -1
            }
        }
        return 0
    }
    /// 获取应用下载信息
    func getAppDownloadInfo(
        trackId: String,
        account: Account,
        appVerId: String? = nil
    ) async -> Result<StoreItem, StoreError> {
        // 为会话设置 cookie
        setCookies(account.cookies)
        do {
            let result = try await StoreRequest.shared.download(
                appIdentifier: trackId,
                directoryServicesIdentifier: account.dsPersonId,
                appVersion: appVerId
            )
            // 检查 songList 是否为空，避免数组越界
            guard !result.songList.isEmpty else {
                return .failure(.invalidItem)
            }
            let item = result.songList[0]
            return .success(item)
        } catch {
            return .failure(.genericError)
        }
    }
    /// 下载应用 IPA 文件
    func downloadApp(
        trackId: String,
        account: Account,
        outputPath: String,
        appVerId: String? = nil,
        purchaseIfNeeded: Bool = false,
        country: String = "US",
        progressCallback: ((Double, String) -> Void)? = nil
    ) async -> Result<String, Error> {
        do {
            // 首先，尝试获取下载信息
            let itemResult = await getAppDownloadInfo(
                trackId: trackId,
                account: account,
                appVerId: appVerId
            )
            var item: StoreItem
            switch itemResult {
            case .success(let storeItem):
                item = storeItem
            case .failure(let error):
                // 如果没有许可证且允许购买，则尝试购买
                if error == .invalidLicense && purchaseIfNeeded {
                    let purchaseResult = await purchaseApp(
                        trackId: trackId,
                        account: account,
                        country: country
                    )
                    switch purchaseResult {
                    case .success(_):
                        // 购买后重试获取下载信息
                        let retryResult = await getAppDownloadInfo(
                            trackId: trackId,
                            account: account,
                            appVerId: appVerId
                        )
                        switch retryResult {
                        case .success(let storeItem):
                            item = storeItem
                        case .failure(let retryError):
                            return .failure(retryError)
                        }
                    case .failure(let purchaseError):
                        return .failure(purchaseError)
                    }
                } else {
                    return .failure(error)
                }
            }
            // 如果未提供输出文件名，则确定输出文件名
            let finalOutputPath: String
            if outputPath.isEmpty {
                finalOutputPath = "\(item.metadata.bundleDisplayName)_\(item.metadata.bundleShortVersionString).ipa"
            } else {
                finalOutputPath = outputPath
            }
            // 下载 IPA 文件
            try await downloadFile(
                from: item.url,
                to: finalOutputPath,
                progressCallback: progressCallback
            )
            // 对 IPA 文件签名
            let signatureClient = SignatureClient(email: "default@example.com")
            try signatureClient.loadFile(path: finalOutputPath)
            try signatureClient.sign()
            try signatureClient.save(to: finalOutputPath)
            return .success(finalOutputPath)
        } catch {
            return .failure(error)
        }
    }
    // MARK: - 文件下载辅助方法
    private func downloadFile(
        from urlString: String,
        to outputPath: String,
        progressCallback: ((Double, String) -> Void)? = nil
    ) async throws {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let expectedLength = httpResponse.expectedContentLength
        let outputURL = URL(fileURLWithPath: outputPath)
        // 创建输出文件
        FileManager.default.createFile(atPath: outputPath, contents: nil, attributes: nil)
        let fileHandle = try FileHandle(forWritingTo: outputURL)
        defer { fileHandle.closeFile() }
        var downloadedBytes: Int64 = 0
        var lastUpdateTime = Date()
        var lastDownloadedBytes: Int64 = 0
        let updateInterval: TimeInterval = 0.5 // 每 0.5 秒更新一次
        // 使用更大的块以提高性能
        var buffer = Data()
        let chunkSize = 8192 // 8KB 块
        for try await byte in asyncBytes {
            buffer.append(byte)
            // 分块写入以提高性能
            if buffer.count >= chunkSize {
                fileHandle.write(buffer)
                downloadedBytes += Int64(buffer.count)
                buffer.removeAll()
                // 定期更新进度
                let now = Date()
                if now.timeIntervalSince(lastUpdateTime) >= updateInterval {
                    updateProgress(
                        downloadedBytes: downloadedBytes,
                        totalBytes: expectedLength,
                        lastBytes: lastDownloadedBytes,
                        timeInterval: now.timeIntervalSince(lastUpdateTime),
                        progressCallback: progressCallback
                    )
                    lastUpdateTime = now
                    lastDownloadedBytes = downloadedBytes
                }
            }
        }
        // 写入剩余缓冲区
        if !buffer.isEmpty {
            fileHandle.write(buffer)
            downloadedBytes += Int64(buffer.count)
        }
        // 最终进度更新
        if expectedLength > 0 {
            let progress = Double(downloadedBytes) / Double(expectedLength)
            let downloadedSize = ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
            let totalSize = ByteCountFormatter.string(fromByteCount: expectedLength, countStyle: .file)
            progressCallback?(progress, "\(downloadedSize) of \(totalSize) - 完成")
        }
    }
    private func updateProgress(
        downloadedBytes: Int64,
        totalBytes: Int64,
        lastBytes: Int64,
        timeInterval: TimeInterval,
        progressCallback: ((Double, String) -> Void)?
    ) {
        guard totalBytes > 0 else { return }
        let progress = Double(downloadedBytes) / Double(totalBytes)
        let downloadedSize = ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        // 计算下载速度
        let bytesPerSecond = Double(downloadedBytes - lastBytes) / timeInterval
        let speedString = ByteCountFormatter.string(fromByteCount: Int64(bytesPerSecond), countStyle: .file) + "/s"
        // 计算剩余时间
        let remainingBytes = totalBytes - downloadedBytes
        let remainingTime: String
        if bytesPerSecond > 0 {
            let seconds = Double(remainingBytes) / bytesPerSecond
            remainingTime = formatTime(seconds)
        } else {
            remainingTime = "计算中..."
        }
        let progressText = "\(downloadedSize) / \(totalSize) - \(speedString) - 剩余: \(remainingTime)"
        progressCallback?(progress, progressText)
    }
    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 {
            return "\(Int(seconds))秒"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            let remainingSeconds = Int(seconds.truncatingRemainder(dividingBy: 60))
            return "\(minutes)分\(remainingSeconds)秒"
        } else {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)小时\(minutes)分钟"
        }
    }
    // MARK: - Cookie 管理
    private func getCookies() -> [String] {
        // 这里将填充来自已认证会话的实际 cookie 值
        return []
    }
    private func setCookies(_ cookieStrings: [String]) {
        AuthenticationManager.shared.setCookies(cookieStrings)
    }
}
// MARK: - 便捷扩展
extension StoreClient {
    /// 完整工作流程：身份验证、搜索和下载
    func authenticateAndDownload(
        email: String,
        password: String,
        mfaCode: String? = nil,
        bundleId: String? = nil,
        trackId: String? = nil,
        outputPath: String = "",
        appVerId: String? = nil,
        purchaseIfNeeded: Bool = false,
        country: String = "US",
        deviceFamily: String = "phone",
        progressCallback: ((Double, String) -> Void)? = nil
    ) async -> Result<String, Error> {
        // 步骤 1: 身份验证
        let authResult = await authenticate(email: email, password: password, mfaCode: mfaCode)
        guard case .success(let account) = authResult else {
            if case .failure(let error) = authResult {
                return .failure(error)
            }
            return .failure(StoreError.genericError)
        }
        // 步骤 2: 获取曲目 ID
        guard let bundleId = bundleId else {
            return .failure(StoreError.invalidItem)
        }
        do {
            guard let finalTrackId = try await getTrackId(
                bundleIdentifier: bundleId,
                countryCode: country,
                deviceFamily: deviceFamily
            ) else {
                return .failure(StoreError.invalidItem)
            }
            // 步骤 3: 下载
            return await downloadApp(
                trackId: String(finalTrackId),
                account: account,
                outputPath: outputPath,
                appVerId: appVerId,
                purchaseIfNeeded: purchaseIfNeeded,
                country: country,
                progressCallback: progressCallback
            )
        } catch {
            return .failure(error)
        }
    }
}