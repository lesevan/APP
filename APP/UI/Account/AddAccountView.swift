import SwiftUI
import Foundation

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    let themeManager: ThemeManager
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.selectedTheme == .dark ? 
                          ModernDarkColors.surfacePrimary : 
                          Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.selectedTheme == .dark ? 
                                   ModernDarkColors.borderPrimary : 
                                   Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(themeManager.selectedTheme == .dark ? .white : .black)
            .accentColor(themeManager.accentColor)
    }
}
struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: AppStore
    @StateObject private var themeManager = ThemeManager.shared
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var code: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showTwoFactorField: Bool = false
    var body: some View {
        NavigationView {
            ZStack {
                // 适配深色模式的背景
                themeManager.backgroundColor
                    .ignoresSafeArea()
                VStack(spacing: 30) {
                    // 标题区域
                    VStack(spacing: 10) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(12) // 添加圆角，模拟iOS应用图标样式
                    }
                    .padding(.top, 20)
                    // 输入表单
                    VStack(spacing: 20) {
                        // Apple ID 输入框
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Apple ID")
                                .font(.headline)
                                .foregroundColor(themeManager.primaryTextColor)
                            TextField("输入您的 Apple ID", text: $email)
                                .textFieldStyle(ModernTextFieldStyle(themeManager: themeManager))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        // 密码输入框
                        VStack(alignment: .leading, spacing: 8) {
                            Text("密码")
                                .font(.headline)
                                .foregroundColor(themeManager.primaryTextColor)
                            SecureField("输入您的密码", text: $password)
                                .textFieldStyle(ModernTextFieldStyle(themeManager: themeManager))
                        }
                        // 双重认证码输入框（条件显示）
                        if showTwoFactorField {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("双重认证码")
                                    .font(.headline)
                                    .foregroundColor(themeManager.primaryTextColor)
                                TextField("输入6位验证码", text: $code)
                                    .textFieldStyle(ModernTextFieldStyle(themeManager: themeManager))
                                    .keyboardType(.numberPad)
                                    .onChange(of: code) { newValue in
                                        // 限制输入长度为6位
                                        if newValue.count > 6 {
                                            code = String(newValue.prefix(6))
                                        }
                                    }
                                Text("请查看您的受信任设备或短信获取验证码")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 20)
                    // 登录按钮
                    Button(action: {
                        Task {
                            await authenticate()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "验证中..." : "添加账户")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal, 20)
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primaryTextColor)
                }
            }
            .onAppear {
                // 保持用户当前的主题设置，不强制重置
            }
        }
    }
    @MainActor
    private func authenticate() async {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "请输入完整的Apple ID和密码"
            return
        }
        
        print("🔐 [AddAccountView] 开始认证流程")
        print("📧 [AddAccountView] Apple ID: \(email)")
        print("🔐 [AddAccountView] 密码长度: \(password.count)")
        print("📱 [AddAccountView] 验证码: \(showTwoFactorField ? code : "无")")
        
        isLoading = true
        errorMessage = ""
        
        do {
            print("🚀 [AddAccountView] 调用vm.addAccount...")
            // 使用AppStore的addAccount方法进行认证和添加
            try await vm.addAccount(
                email: email,
                password: password,
                code: showTwoFactorField ? code : nil
            )
            print("✅ [AddAccountView] 认证成功，关闭视图")
            // 成功后直接关闭视图
            dismiss()
        } catch {
            print("❌ [AddAccountView] 认证失败: \(error)")
            print("❌ [AddAccountView] 错误类型: \(type(of: error))")
            
            isLoading = false
            
            if let storeError = error as? StoreError {
                print("🔍 [AddAccountView] 检测到StoreError: \(storeError)")
                switch storeError {
                case .invalidCredentials:
                    errorMessage = "Apple ID或密码错误，请检查后重试"
                case .codeRequired:
                    print("🔐 [AddAccountView] 需要双重认证码")
                    if !showTwoFactorField {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showTwoFactorField = true
                        }
                    } else {
                        errorMessage = "验证码错误，请检查验证码是否正确"
                    }
                case .lockedAccount:
                    errorMessage = "您的Apple ID已被锁定，请稍后再试或联系Apple支持"
                case .networkError:
                    errorMessage = "在Apple ID认证过程中发生网络错误，请检查您的网络连接后重试"
                case .authenticationFailed:
                    errorMessage = "认证失败，请检查网络连接和账户信息"
                case .invalidResponse:
                    errorMessage = "服务器响应无效，请稍后重试"
                case .unknownError:
                    errorMessage = "未知错误，请稍后重试"
                default:
                    errorMessage = "在Apple ID认证过程中发生错误: \(storeError.localizedDescription)"
                }
            } else {
                print("🔍 [AddAccountView] 未知错误类型: \(error)")
                errorMessage = "在Apple ID认证过程中发生错误: \(error.localizedDescription)"
            }
        }
    }
}
