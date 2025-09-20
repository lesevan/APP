
import SwiftUI
import UniformTypeIdentifiers
import os.log


struct FileImporterRepresentableView: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onDocumentsPicked: ([URL]) -> Void
    
    init(
        allowedContentTypes: [UTType],
        allowsMultipleSelection: Bool = false,
        onDocumentsPicked: @escaping ([URL]) -> Void
    ) {
        self.allowedContentTypes = allowedContentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onDocumentsPicked = onDocumentsPicked
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = iOSCompatibility.shared.createDocumentPicker(for: allowedContentTypes, allowsMultipleSelection: allowsMultipleSelection)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentsPicked: onDocumentsPicked)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentsPicked: ([URL]) -> Void
        private let logger = Logger(subsystem: "com.feather.fileimporter", category: "FileImporter")
        
        init(onDocumentsPicked: @escaping ([URL]) -> Void) {
            self.onDocumentsPicked = onDocumentsPicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            logger.info("选择了 \(urls.count) 个文件")
            onDocumentsPicked(urls)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            logger.info("用户取消了文件选择")
            onDocumentsPicked([])
        }
    }
}

struct CertificatesAddView: View {
	@Environment(\.dismiss) private var dismiss
	
	@State private var _p12URL: URL? = nil
	@State private var _provisionURL: URL? = nil
	@State private var _p12Password: String = ""
	@State private var _certificateName: String = ""
	
	@State private var _isImportingP12Presenting = false
	@State private var _isImportingMobileProvisionPresenting = false
	
	var saveButtonDisabled: Bool {
		_p12URL == nil || _provisionURL == nil
	}
	
	var body: some View {
		NavigationView {
			Form {
				Section("文件") {
					_importButton("导入证书文件", file: _p12URL) {
						_isImportingP12Presenting = true
					}
					_importButton("导入配置文件", file: _provisionURL) {
						_isImportingMobileProvisionPresenting = true
					}
				}
				Section {
					SecureField("输入密码", text: $_p12Password)
				} header: {
					Text("密码")
				} footer: {
					Text("输入与私钥关联的密码。如果没有密码要求，请留空。")
				}
				
				Section {
					TextField("昵称（可选）", text: $_certificateName)
				}
			}
			.navigationTitle("新证书")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("取消") {
						dismiss()
					}
				}
				
				ToolbarItem(placement: .confirmationAction) {
					Button {
						_saveCertificate()
					} label: {
						Text("保存")
					}
					.disabled(saveButtonDisabled)
				}
			}
			.sheet(isPresented: $_isImportingP12Presenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [.p12],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self._p12URL = selectedFileURL
					}
				)
				.ignoresSafeArea()
			}
			.sheet(isPresented: $_isImportingMobileProvisionPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [.mobileProvision],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self._provisionURL = selectedFileURL
					}
				)
				.ignoresSafeArea()
			}
		}
	}
}

extension CertificatesAddView {
	@ViewBuilder
	private func _importButton(
		_ title: String,
		file: URL?,
		action: @escaping () -> Void
	) -> some View {
		HStack {
			Button(title) {
				action()
			}
			.foregroundColor(.accentColor)
			
			Spacer()
			
			if let file = file {
				Text(file.lastPathComponent)
					.font(.caption)
					.foregroundColor(.secondary)
					.lineLimit(1)
			}
		}
	}
}

extension CertificatesAddView {
	private func _saveCertificate() {
		guard
			let p12URL = _p12URL,
			let provisionURL = _provisionURL,
			FR.checkPasswordForCertificate(for: p12URL, with: _p12Password, using: provisionURL)
		else {
			UIAlertController.showAlertWithOk(
				title: "密码错误",
				message: "请检查密码并重试。"
			)
			return
		}
		
		FR.handleCertificateFiles(
			p12URL: p12URL,
			provisionURL: provisionURL,
			p12Password: _p12Password,
			certificateName: _certificateName
		) { _ in
			dismiss()
		}
	}
}

