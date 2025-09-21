import SwiftUI
import Foundation

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.primary)
    }
}
@MainActor
struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: AppStore
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var code: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showTwoFactorField: Bool = false
    @FocusState private var isCodeFieldFocused: Bool
    var body: some View {
        NavigationView {
            ZStack {
                // 适配深色模式的背景
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部安全区域占位
                    GeometryReader { geometry in
                        Color.clear
                            .frame(height: geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top : 44)
                    }
                    .frame(height: 44)
                    
                    // 主要内容区域 - 完美居中
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // 标题区域 - 完全居中
                        VStack(spacing: 20) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: 8) {
                                Text("Apple ID")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("登录您的账户")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // 输入表单区域
                        VStack(spacing: 24) {
                            // Apple ID 输入框
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Apple ID")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                TextField("输入您的 Apple ID", text: $email)
                                    .textFieldStyle(ModernTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            
                            // 密码输入框
                            VStack(alignment: .leading, spacing: 8) {
                                Text("密码")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                SecureField("输入您的密码", text: $password)
                                    .textFieldStyle(ModernTextFieldStyle())
                            }
                            
                            // 双重认证码输入框（条件显示）
                            if showTwoFactorField {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("双重认证码")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    TextField("输入6位验证码", text: $code)
                                        .textFieldStyle(ModernTextFieldStyle())
                                        .keyboardType(.numberPad)
                                        .focused($isCodeFieldFocused)
                                        .onChange(of: code) { newValue in
                                            // 限制输入长度为6位
                                            if newValue.count > 6 {
                                                code = String(newValue.prefix(6))
                                            }
                                            
                                            // 当输入6位验证码时自动缩回键盘并开始认证
                                            if newValue.count == 6 {
                                                // 延迟一点时间让用户看到输入完成
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    // 缩回键盘
                                                    isCodeFieldFocused = false
                                                    
                                                    // 自动开始认证
                                                    Task {
                                                        await authenticate()
                                                    }
                                                }
                                            }
                                        }
                                    Text("请查看您的受信任设备或短信获取验证码")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        
                        // 登录按钮区域
                        VStack(spacing: 16) {
                            Button(action: {
                                Task {
                                    await authenticate()
                                }
                            }) {
                                HStack(spacing: 12) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.title2)
                                    }
                                    Text(isLoading ? "验证中..." : "添加账户")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: themeManager.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            
                            // 错误信息显示
                            if !errorMessage.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("取消") {
                dismiss()
            }.foregroundColor(.primary))
            .onTapGesture {
                // 点击背景缩回键盘
                isCodeFieldFocused = false
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
        
        // 缩回键盘
        isCodeFieldFocused = false
        
        do {
            print("🚀 [AddAccountView] 调用vm.loginAccount...")
            // 使用AppStore的loginAccount方法进行认证和登录
            try await vm.loginAccount(
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
                        // 延迟聚焦到验证码输入框
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isCodeFieldFocused = true
                        }
                    } else {
                        errorMessage = "验证码错误，请检查验证码是否正确"
                        // 重新聚焦到验证码输入框
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isCodeFieldFocused = true
                        }
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