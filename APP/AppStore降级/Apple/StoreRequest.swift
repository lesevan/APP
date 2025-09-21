//
//  StoreRequest.swift
//  APP
//
//  Created by pxx917144686 on 2025/08/20.
//
import Foundation
import CryptoKit
/// 用于处理SSL和身份验证挑战的URLSession代理
class StoreRequestDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // 处理SSL证书验证
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        // 对于Apple的域名，使用默认验证
        let host = challenge.protectionSpace.host
        if host.hasSuffix(".apple.com") || host.hasSuffix(".itunes.apple.com") {
            completionHandler(.performDefaultHandling, nil)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
/// 用于身份验证、下载和购买的Store API请求处理器
@MainActor
class StoreRequest: @unchecked Sendable {
    static let shared = StoreRequest()
    // 统一GUID：确保认证/购买/下载使用同一个GUID
    @MainActor
    private static var cachedGUID: String?
    private let session: URLSession
    private let baseURL = "https://p25-buy.itunes.apple.com"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        // 添加Cookie存储
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        // 修复SSL连接问题
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.tlsMaximumSupportedProtocolVersion = .TLSv13
        self.session = URLSession(configuration: config, delegate: StoreRequestDelegate(), delegateQueue: nil)
    }
    /// 使用Apple ID验证用户身份
    /// - 参数:
    ///   - email: Apple ID邮箱
    ///   - password: Apple ID密码
    ///   - mfa: 双重认证码（可选）
    /// - 返回值: 认证响应
    func authenticate(
        email: String,
        password: String,
        mfa: String? = nil
    ) async throws -> StoreAuthResponse {
        print("🚀 [认证开始] 开始Apple ID认证流程")
        print("📧 [认证参数] Apple ID: \(email)")
        print("🔐 [认证参数] 密码长度: \(password.count) 字符")
        print("📱 [认证参数] 双重认证码: \(mfa != nil ? "已提供(\(mfa!.count)位)" : "未提供")")
        let guid = acquireGUID()
        print("🆔 [设备信息] 生成的GUID: \(guid)")
        let url = URL(string: "https://auth.itunes.apple.com/auth/v1/native/fast?guid=\(guid)")!
        print("🌐 [请求URL] \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-apple-plist", forHTTPHeaderField: "Content-Type")
        request.setValue(getUserAgent(), forHTTPHeaderField: "User-Agent")
        print("📋 [请求头] Content-Type: application/x-apple-plist")
        print("📋 [请求头] User-Agent: \(getUserAgent())")
        // 修复认证参数构建
        let attempt = mfa != nil ? 2 : 4
        let passwordWithMFA = password + (mfa ?? "")
        print("🔢 [认证参数] attempt: \(attempt)")
        print("🔐 [认证参数] 合并后密码长度: \(passwordWithMFA.count) 字符")
        let bodyDict: [String: Any] = [
            "appleId": email,
            "attempt": attempt,
            "createSession": "true",
            "guid": guid,
            "password": passwordWithMFA,
            "rmp": "0",
            "why": "signIn"
        ]
        print("📦 [请求体] 构建认证参数: \(bodyDict.keys.sorted())")
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: bodyDict,
            format: .xml,
            options: 0
        )
        request.httpBody = plistData
        print("📤 [发送请求] 请求体大小: \(plistData.count) 字节")
        print("⏳ [网络请求] 正在发送认证请求到Apple服务器...")
        let (data, response) = try await session.data(for: request)
        print("📥 [响应接收] 收到服务器响应，数据大小: \(data.count) 字节")
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [网络错误] 无法获取HTTP响应")
            throw StoreError.invalidResponse
        }
        print("📊 [响应状态] HTTP状态码: \(httpResponse.statusCode)")
        print("📋 [响应头] 所有响应头: \(httpResponse.allHeaderFields)")
        let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] ?? [:]
        print("📄 [响应解析] 成功解析plist格式响应")
        print("🔍 [响应内容] 响应包含的所有键: \(Array(plist.keys).sorted())")
        print("📝 [响应详情] 完整响应内容: \(plist)")
        // 检查根级别的dsPersonId
        let possibleRootKeys = ["dsPersonId", "dsPersonID", "dsid", "DSID", "directoryServicesIdentifier"]
        for key in possibleRootKeys {
            if let value = plist[key] {
                print("✅ [DSID检查] 在根级别找到键 '\(key)': \(value)")
            }
        }
        // 增强2FA错误检测
        if let customerMessage = plist["customerMessage"] as? String {
            print("💬 [服务器消息] customerMessage: \(customerMessage)")
            if customerMessage == "MZFinance.BadLogin.Configurator_message" ||
               customerMessage.contains("verification code is required") {
                print("🔐 [双重认证] 检测到需要双重认证码")
                throw StoreError.codeRequired
            }
        }
        // 检查错误信息
        if let failureType = plist["failureType"] as? String {
            print("❌ [认证失败] failureType: \(failureType)")
        }
        if let errorMessage = plist["errorMessage"] as? String {
            print("❌ [错误消息] errorMessage: \(errorMessage)")
        }
        print("🔄 [解析响应] 开始解析认证响应...")
        let result = try parseAuthResponse(plist: plist, httpResponse: httpResponse)
        print("✅ [认证完成] 认证流程处理完毕")
        return result
    }
    /// Download app information
    /// - Parameters:
    ///   - appIdentifier: App identifier
    ///   - directoryServicesIdentifier: User's DSID
    ///   - appVersion: Specific app version (optional)
    ///   - passwordToken: User's password token for authentication
    ///   - storeFront: Store front identifier
    /// - Returns: Download response with app information
    func download(
        appIdentifier: String,
        directoryServicesIdentifier: String,
        appVersion: String? = nil,
        passwordToken: String? = nil,
        storeFront: String? = nil
    ) async throws -> StoreDownloadResponse {
        let guid = acquireGUID()
        let url = URL(string: "\(baseURL)/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct?guid=\(guid)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-apple-plist", forHTTPHeaderField: "Content-Type")
        request.setValue(getUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue(directoryServicesIdentifier, forHTTPHeaderField: "X-Dsid")
        request.setValue(directoryServicesIdentifier, forHTTPHeaderField: "iCloud-DSID")
        // 添加关键的认证请求头
        if let passwordToken = passwordToken {
            request.setValue(passwordToken, forHTTPHeaderField: "X-Token")
        }
        if let storeFront = storeFront {
            request.setValue(normalizeStoreFront(storeFront), forHTTPHeaderField: "X-Apple-Store-Front")
        }
        // 修复请求体参数
        var body: [String: Any] = [
            "creditDisplay": "",
            "guid": guid,
            "salableAdamId": appIdentifier
        ]
        // 支持字符串和数字类型的版本ID，确保请求总是包含版本参数
        if let appVersion = appVersion {
            // 首先尝试作为整数解析
            if let versionId = Int(appVersion) {
                body["externalVersionId"] = versionId
            } else {
                // 如果无法解析为整数，直接使用字符串值
                body["externalVersionId"] = appVersion
            }
        }
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: body,
            format: .xml,
            options: 0
        )
        request.httpBody = plistData
        // 添加请求体调试信息
        if let bodyString = String(data: plistData, encoding: .utf8) {
            print("[DEBUG] Request body: \(bodyString)")
        }
        print("[DEBUG] Request URL: \(url)")
        print("[DEBUG] Request headers: \(request.allHTTPHeaderFields ?? [:])")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StoreError.invalidResponse
        }
        let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] ?? [:]
        return try parseDownloadResponse(plist: plist, httpResponse: httpResponse)
    }
    /// Purchase app
    /// - Parameters:
    ///   - appIdentifier: App identifier
    ///   - directoryServicesIdentifier: User's DSID
    ///   - passwordToken: User's password token
    ///   - storeFront: X-Apple-Store-Front header value (from account)
    /// - Returns: Purchase response
    func purchase(
        appIdentifier: String,
        directoryServicesIdentifier: String,
        passwordToken: String,
        storeFront: String
    ) async throws -> StorePurchaseResponse {
        let guid = acquireGUID()
        // 购买需走 buy.itunes.apple.com，不使用 p25 分片域
        let url = URL(string: "https://buy.itunes.apple.com/WebObjects/MZBuy.woa/wa/buyProduct")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // 购买接口同样接受 plist 体，这里统一采用 plist
        request.setValue("application/x-apple-plist", forHTTPHeaderField: "Content-Type")
        request.setValue(getUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue(directoryServicesIdentifier, forHTTPHeaderField: "X-Dsid")
        request.setValue(directoryServicesIdentifier, forHTTPHeaderField: "iCloud-DSID")
        request.setValue(normalizeStoreFront(storeFront), forHTTPHeaderField: "X-Apple-Store-Front")
        request.setValue(passwordToken, forHTTPHeaderField: "X-Token")
        // 对齐 ipatool 的购买参数，尽量模拟官方客户端静默获取流程
        var body: [String: Any] = [
            "guid": guid,
            "salableAdamId": appIdentifier,
            "dsPersonId": directoryServicesIdentifier,
            "passwordToken": passwordToken,
            "price": "0",
            "pricingParameters": "STDQ",
            "productType": "C",
            "appExtVrsId": "0",
            "hasAskedToFulfillPreorder": "true",
            "buyWithoutAuthorization": "true",
            "hasDoneAgeCheck": "true",
            "needDiv": "0",
            "origPage": "Software-\(appIdentifier)",
            "origPageLocation": "Buy"
        ]
        // 尝试增加 signal 参数以模拟前端交互
        body["pg"] = "default"
        body["sd"] = "true"
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: body,
            format: .xml,
            options: 0
        )
        request.httpBody = plistData
        // 调试输出
        if let bodyString = String(data: plistData, encoding: .utf8) {
            print("[DEBUG][BUY] Request body: \(bodyString)")
        }
        print("[DEBUG][BUY] Request URL: \(url)")
        print("[DEBUG][BUY] Request headers: \(request.allHTTPHeaderFields ?? [:])")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StoreError.invalidResponse
        }
        let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] ?? [:]
        print("[DEBUG][BUY] HTTP Status Code: \(httpResponse.statusCode)")
        print("[DEBUG][BUY] Response keys: \(plist.keys.sorted())")
        return try parsePurchaseResponse(plist: plist, httpResponse: httpResponse)
    }
    // MARK: - 私有辅助方法
    /// Generate user agent string
    private func getUserAgent() -> String {
        return "Configurator/2.15 (Macintosh; OS X 11.0.0; 16G29) AppleWebKit/2603.3.8"
    }
    /// 规范化 StoreFront 头部：取纯数字代码（例如 "143441"），避免携带地区后缀（如 "-1,29"）导致购买异常
    private func normalizeStoreFront(_ value: String) -> String {
        // 只保留前面的数字部分
        let digitsPrefix = value.split(separator: "-").first.map(String.init) ?? value
        // 若仍包含逗号后的参数，继续截断
        return digitsPrefix.split(separator: ",").first.map(String.init) ?? digitsPrefix
    }
    /// Acquire a stable GUID for the session (persist for all requests)
    private func acquireGUID() -> String {
        if let g = StoreRequest.cachedGUID, !g.isEmpty, g != "000000000000" { return g }
        // 尝试基于设备信息生成；若不可用则生成随机12位HEX
        let generated = Self.generateFallbackGUID()
        StoreRequest.cachedGUID = generated
        return generated
    }
    /// 生成随机12位大写HEX，替代不可用的MAC
    private static func generateFallbackGUID() -> String {
        let hex = "0123456789ABCDEF"
        var out = ""
        for _ in 0..<12 { out.append(hex.randomElement()!) }
        return out
    }
    /// 供外部（如下载管理器）读取当前GUID
    func currentGUID() -> String { acquireGUID() }
    /// Parse authentication response
    private func parseAuthResponse(
        plist: [String: Any],
        httpResponse: HTTPURLResponse
    ) throws -> StoreAuthResponse {
        print("🔍 [解析开始] parseAuthResponse - 状态码: \(httpResponse.statusCode)")
        if httpResponse.statusCode == 200 {
            print("✅ [状态检查] HTTP 200 - 认证请求成功")
            // 检查所有可能的dsPersonId键名变体
            let possibleKeys = ["dsPersonId", "dsPersonID", "dsid", "DSID", "directoryServicesIdentifier"]
            print("🔍 [DSID搜索] 在根级别搜索可能的DSID键名: \(possibleKeys)")
            for key in possibleKeys {
                if let value = plist[key] {
                    print("🔍 [DEBUG] 找到键 '\(key)': \(value)")
                }
            }
        print("📋 [账户信息] 开始解析accountInfo...")
        let accountInfo = parseAccountInfo(from: plist)
        print("🔐 [令牌解析] 搜索passwordToken...")
        let passwordToken = plist["passwordToken"] as? String ?? ""
        print("🔐 [令牌结果] passwordToken: '\(passwordToken.isEmpty ? "空" : "已获取(\(passwordToken.count)字符)")")
        
        // 增强地区信息检测
        print("🌍 [地区检测] 开始检测地区信息...")
        if let accountInfo = accountInfo {
            print("🌍 [地区检测] accountInfo.countryCode: '\(accountInfo.countryCode ?? "空")'")
            print("🌍 [地区检测] accountInfo.storeFront: '\(accountInfo.storeFront ?? "空")'")
        } else {
            print("🌍 [地区检测] accountInfo为空，无法获取地区信息")
        }
            print("🆔 [DSID解析] 在根级别搜索dsPersonId...")
            // 尝试多种可能的键名
            let dsPersonId = (plist["dsPersonId"] as? String) ?? 
                           (plist["dsPersonID"] as? String) ?? 
                           (plist["dsid"] as? String) ?? 
                           (plist["DSID"] as? String) ?? 
                           (plist["directoryServicesIdentifier"] as? String) ?? ""
            print("🆔 [DSID结果] 根级别dsPersonId: '\(dsPersonId.isEmpty ? "空" : dsPersonId)'")
            print("📡 [Pings解析] 搜索pings数组...")
            let pings = plist["pings"] as? [String]
            print("📡 [Pings结果] pings: \(pings?.count ?? 0) 个项目")
            // 获取accountInfo中的dsPersonId作为备用
            let accountDsPersonId = accountInfo?.dsPersonId ?? ""
            print("👤 [账户DSID] accountInfo中的dsPersonId: '\(accountDsPersonId.isEmpty ? "空" : accountDsPersonId)'")
            // 选择最终的dsPersonId（优先使用根级别的，然后是accountInfo中的）
            let finalDsPersonId = !dsPersonId.isEmpty ? dsPersonId : accountDsPersonId
            print("✅ [最终DSID] 选定的dsPersonId: '\(finalDsPersonId.isEmpty ? "空" : finalDsPersonId)'")
            print("🏗️ [构建响应] 创建StoreAuthResponse对象...")
            let response = StoreAuthResponse(
                accountInfo: accountInfo ?? StoreAuthResponse.AccountInfo(
                    appleId: "",
                    address: StoreAuthResponse.AccountInfo.Address(
                        firstName: "",
                        lastName: ""
                    ),
                    dsPersonId: finalDsPersonId,
                    countryCode: nil,
                    storeFront: nil
                ),
                passwordToken: passwordToken,
                dsPersonId: finalDsPersonId,
                pings: pings
            )
            print("✅ [响应完成] StoreAuthResponse创建成功")
            print("📊 [响应摘要] AppleID: \(response.accountInfo.appleId)")
            print("📊 [响应摘要] DSID: \(response.dsPersonId.isEmpty ? "空" : response.dsPersonId)")
            print("📊 [响应摘要] Token: \(response.passwordToken.isEmpty ? "空" : "已获取")")
            return response
        } else {
            print("❌ [认证失败] HTTP状态码: \(httpResponse.statusCode)")
            let failureType = plist["failureType"] as? String ?? ""
            let customerMessage = plist["customerMessage"] as? String ?? ""
            print("❌ [失败类型] failureType: \(failureType)")
            print("💬 [客户消息] customerMessage: \(customerMessage)")
            if let errorMessage = plist["errorMessage"] as? String {
                print("💬 [错误消息] errorMessage: \(errorMessage)")
            }
            print("🔍 [错误详情] 完整错误响应: \(plist)")
            // 处理特殊的认证响应情况
            if !failureType.isEmpty {
                throw StoreError.fromFailureType(failureType)
            } else if customerMessage == "MZFinance.BadLogin.Configurator_message" {
                throw StoreError.codeRequired
            } else if customerMessage.contains("AMD-Action") {
                // AMD安全挑战
                print("⚠️ [AMD挑战] 检测到AMD安全挑战，尝试继续处理...")
                // 创建一个空的成功响应，让调用者处理
                let emptyResponse = StoreAuthResponse(
                    accountInfo: StoreAuthResponse.AccountInfo(
                        appleId: "",
                        address: StoreAuthResponse.AccountInfo.Address(
                            firstName: "",
                            lastName: ""
                        ),
                        dsPersonId: "",
                        countryCode: "US",
                        storeFront: nil
                    ),
                    passwordToken: "",
                    dsPersonId: "",
                    pings: []
                )
                return emptyResponse
            } else {
                throw StoreError.unknownError
            }
        }
    }
    /// Parse account information from plist
    private func parseAccountInfo(from plist: [String: Any]) -> StoreAuthResponse.AccountInfo? {
        guard let accountInfo = plist["accountInfo"] as? [String: Any] else {
            print("🔍 [DEBUG] parseAccountInfo: 未找到 accountInfo 字段")
            return nil
        }
        print("🔍 [DEBUG] parseAccountInfo: accountInfo 内容: \(accountInfo)")
        print("🔍 [DEBUG] parseAccountInfo: accountInfo 所有键: \(Array(accountInfo.keys))")
        let appleId = accountInfo["appleId"] as? String ?? ""
        let address = accountInfo["address"] as? [String: Any]
        let firstName = address?["firstName"] as? String ?? ""
        let lastName = address?["lastName"] as? String ?? ""
        // 检查所有可能的dsPersonId键名变体
        let possibleKeys = ["dsPersonId", "dsPersonID", "dsid", "DSID", "directoryServicesIdentifier"]
        for key in possibleKeys {
            if let value = accountInfo[key] {
                print("🔍 [DEBUG] parseAccountInfo: 找到键 '\(key)': \(value)")
            }
        }
        // 尝试多种可能的键名
        let dsPersonId = (accountInfo["dsPersonId"] as? String) ?? 
                        (accountInfo["dsPersonID"] as? String) ?? 
                        (accountInfo["dsid"] as? String) ?? 
                        (accountInfo["DSID"] as? String) ?? 
                        (accountInfo["directoryServicesIdentifier"] as? String) ?? ""
        print("🔍 [DEBUG] parseAccountInfo: 最终获取的 dsPersonId: '\(dsPersonId)')")
        
        // 增强地区信息检测
        let countryCode = detectCountryCodeFromAccountInfo(accountInfo)
        let storeFront = detectStoreFrontFromAccountInfo(accountInfo)
        
        print("🌍 [地区解析] 检测到的countryCode: '\(countryCode ?? "空")'")
        print("🏪 [商店解析] 检测到的storeFront: '\(storeFront ?? "空")'")
        
        return StoreAuthResponse.AccountInfo(
            appleId: appleId,
            address: StoreAuthResponse.AccountInfo.Address(
                firstName: firstName,
                lastName: lastName
            ),
            dsPersonId: dsPersonId,
            countryCode: countryCode,
            storeFront: storeFront
        )
    }
    
    /// 从账户信息中检测地区代码
    private func detectCountryCodeFromAccountInfo(_ accountInfo: [String: Any]) -> String? {
        // 1. 直接获取countryCode
        if let countryCode = accountInfo["countryCode"] as? String, !countryCode.isEmpty {
            print("🌍 [地区检测] 直接获取countryCode: \(countryCode)")
            return countryCode
        }
        
        // 2. 从storeFront推断
        if let storeFront = accountInfo["storeFront"] as? String, !storeFront.isEmpty {
            let inferredCountryCode = inferCountryCodeFromStoreFront(storeFront)
            if inferredCountryCode != "US" {
                print("🌍 [地区检测] 从storeFront推断countryCode: \(inferredCountryCode)")
                return inferredCountryCode
            }
        }
        
        // 3. 检查其他可能的地区相关字段
        let regionFields = ["region", "country", "locale", "territory", "market"]
        for field in regionFields {
            if let value = accountInfo[field] as? String, !value.isEmpty {
                print("🌍 [地区检测] 从\(field)字段获取: \(value)")
                return value.uppercased()
            }
        }
        
        return nil
    }
    
    /// 从账户信息中检测StoreFront
    private func detectStoreFrontFromAccountInfo(_ accountInfo: [String: Any]) -> String? {
        // 1. 直接获取storeFront
        if let storeFront = accountInfo["storeFront"] as? String, !storeFront.isEmpty {
            print("🏪 [商店检测] 直接获取storeFront: \(storeFront)")
            return storeFront
        }
        
        // 2. 检查其他可能的商店相关字段
        let storeFields = ["storefront", "storeFront", "store_front", "marketId", "market_id"]
        for field in storeFields {
            if let value = accountInfo[field] as? String, !value.isEmpty {
                print("🏪 [商店检测] 从\(field)字段获取: \(value)")
                return value
            }
        }
        
        return nil
    }
    
    /// 从StoreFront推断地区代码
    private func inferCountryCodeFromStoreFront(_ storeFront: String) -> String {
        // 提取StoreFront的数字部分
        let storeFrontCode = storeFront.components(separatedBy: "-").first ?? storeFront
        
        // 反向查找地区代码映射
        for (countryCode, code) in Apple.storeFrontCodeMap {
            if code == storeFrontCode {
                return countryCode
            }
        }
        
        return "US" // 默认值
    }
    /// Parse download response
    private func parseDownloadResponse(
        plist: [String: Any],
        httpResponse: HTTPURLResponse
    ) throws -> StoreDownloadResponse {
        // 添加调试日志
        print("[DEBUG] HTTP Status Code: \(httpResponse.statusCode)")
        print("[DEBUG] Response plist keys: \(plist.keys.sorted())")
        if let songListRaw = plist["songList"] {
            print("[DEBUG] songList type: \(type(of: songListRaw))")
            print("[DEBUG] songList content: \(songListRaw)")
        } else {
            print("[DEBUG] songList not found in response")
        }
        
        if httpResponse.statusCode == 200 {
            var songList: [StoreItem] = []
            if let songs = plist["songList"] as? [[String: Any]] {
                songList = songs.compactMap { parseStoreItem(from: $0) }
            }
            print("[DEBUG] Parsed songList count: \(songList.count)")
            
            // 如果songList为空，抛出invalidLicense错误
            if songList.isEmpty {
                print("[DEBUG] songList为空，用户可能未购买此应用")
                throw StoreError.invalidLicense
            }
            
            let dsPersonId = plist["dsPersonID"] as? String ?? ""
            let jingleDocType = plist["jingleDocType"] as? String
            let jingleAction = plist["jingleAction"] as? String
            let pings = plist["pings"] as? [String]
            return StoreDownloadResponse(
                songList: songList,
                dsPersonId: dsPersonId,
                jingleDocType: jingleDocType,
                jingleAction: jingleAction,
                pings: pings
            )
        } else {
            let failureType = plist["failureType"] as? String ?? "unknownError"
            print("[DEBUG] Error response - failureType: \(failureType)")
            throw StoreError.fromFailureType(failureType)
        }
    }
    /// Parse store item from plist
    private func parseStoreItem(from dict: [String: Any]) -> StoreItem? {
        guard let url = dict["URL"] as? String,
              let md5 = dict["md5"] as? String else {
            return nil
        }
        var sinfs: [SinfInfo] = []
        if let sinfsArray = dict["sinfs"] as? [[String: Any]] {
            sinfs = sinfsArray.compactMap { sinfDict in
                guard let id = sinfDict["id"] as? Int,
                      let sinfString = sinfDict["sinf"] as? String else {
                    return nil
                }
                return SinfInfo(id: id, sinf: sinfString)
            }
        }
        var metadata: AppMetadata
        if let metadataDict = dict["metadata"] as? [String: Any] {
            // 修复字段名映射问题
            let bundleId = metadataDict["softwareVersionBundleId"] as? String ?? 
                          metadataDict["bundle-identifier"] as? String ?? ""
            let bundleDisplayName = metadataDict["bundleDisplayName"] as? String ?? 
                                   metadataDict["itemName"] as? String ?? 
                                   metadataDict["item-name"] as? String ?? ""
            let bundleShortVersionString = metadataDict["bundleShortVersionString"] as? String ?? 
                                          metadataDict["bundle-short-version-string"] as? String ?? ""
            let softwareVersionExternalIdentifier = String(metadataDict["softwareVersionExternalIdentifier"] as? Int ?? 0)
            let softwareVersionExternalIdentifiers = metadataDict["softwareVersionExternalIdentifiers"] as? [Int]
            print("[DEBUG] 解析metadata字段:")
            print("[DEBUG] - bundleId: \(bundleId)")
            print("[DEBUG] - bundleDisplayName: \(bundleDisplayName)")
            print("[DEBUG] - bundleShortVersionString: \(bundleShortVersionString)")
            print("[DEBUG] - softwareVersionExternalIdentifier: \(softwareVersionExternalIdentifier)")
            print("[DEBUG] - softwareVersionExternalIdentifiers count: \(softwareVersionExternalIdentifiers?.count ?? 0)")
            metadata = AppMetadata(
                bundleId: bundleId,
                bundleDisplayName: bundleDisplayName,
                bundleShortVersionString: bundleShortVersionString,
                softwareVersionExternalIdentifier: softwareVersionExternalIdentifier,
                softwareVersionExternalIdentifiers: softwareVersionExternalIdentifiers
            )
        } else {
            metadata = AppMetadata(
                bundleId: "",
                bundleDisplayName: "",
                bundleShortVersionString: "",
                softwareVersionExternalIdentifier: "",
                softwareVersionExternalIdentifiers: nil
            )
        }
        return StoreItem(
            url: url,
            md5: md5,
            sinfs: sinfs,
            metadata: metadata
        )
    }
    /// Parse purchase response
    private func parsePurchaseResponse(
        plist: [String: Any],
        httpResponse: HTTPURLResponse
    ) throws -> StorePurchaseResponse {
        if httpResponse.statusCode == 200 {
            // 如果返回包含 dialog 或 failureType，表示需要用户在官方 App Store 进行交互
            if plist["dialog"] != nil || plist["failureType"] != nil {
                throw StoreError.userInteractionRequired
            }
            let dsPersonId = plist["dsPersonID"] as? String ?? ""
            let jingleDocType = plist["jingleDocType"] as? String
            let jingleAction = plist["jingleAction"] as? String
            let pings = plist["pings"] as? [String]
            return StorePurchaseResponse(
                dsPersonId: dsPersonId,
                jingleDocType: jingleDocType,
                jingleAction: jingleAction,
                pings: pings
            )
        } else {
            throw StoreError.fromFailureType(plist["failureType"] as? String ?? "unknownError")
        }
    }
}
// MARK: - 响应类型
enum StoreError: Error, LocalizedError, Equatable {
    case networkError(Error)
    case invalidResponse
    case authenticationFailed
    case accountNotFound
    case invalidCredentials
    case serverError(Int)
    case unknown(String)
    case genericError
    case invalidItem
    case invalidLicense
    case unknownError
    case codeRequired
    case lockedAccount
    case keychainError
    case userInteractionRequired
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed:
            return "Authentication failed"
        case .accountNotFound:
            return "Account not found"
        case .invalidCredentials:
            return "Invalid credentials"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .genericError:
            return "Generic error occurred"
        case .invalidItem:
            return "Invalid item"
        case .invalidLicense:
            return "Invalid license"
        case .codeRequired:
            return "Verification code required"
        case .lockedAccount:
            return "Account is locked"
        case .keychainError:
            return "Keychain error occurred"
        case .userInteractionRequired:
            return "需要在 App Store 完成一次身份验证/获取"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
    static func fromFailureType(_ failureType: String) -> StoreError {
        switch failureType {
        case "authenticationFailed":
            return .authenticationFailed
        case "accountNotFound":
            return .accountNotFound
        case "invalidCredentials":
            return .invalidCredentials
        case "codeRequired":
            return .codeRequired
        case "lockedAccount":
            return .lockedAccount
        default:
            return .unknownError
        }
    }
    static func == (lhs: StoreError, rhs: StoreError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse),
             (.authenticationFailed, .authenticationFailed),
             (.accountNotFound, .accountNotFound),
             (.invalidCredentials, .invalidCredentials),
             (.genericError, .genericError),
             (.invalidItem, .invalidItem),
             (.invalidLicense, .invalidLicense),
             (.unknownError, .unknownError):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}
struct StoreAuthResponse: Codable {
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

// MARK: - 响应类型定义
struct StoreDownloadResponse: Codable {
    let songList: [StoreItem]
    let dsPersonId: String
    let jingleDocType: String?
    let jingleAction: String?
    let pings: [String]?
}

struct StorePurchaseResponse: Codable {
    let dsPersonId: String
    let jingleDocType: String?
    let jingleAction: String?
    let pings: [String]?
}

struct StoreItem: Codable {
    let url: String
    let md5: String
    let sinfs: [SinfInfo]
    let metadata: AppMetadata
}

struct AppMetadata: Codable {
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

struct SinfInfo: Codable {
    let id: Int
    let sinf: String
}