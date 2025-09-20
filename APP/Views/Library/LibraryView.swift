import SwiftUI
import CoreData
import UniformTypeIdentifiers
import os.log

struct LibraryView: View {
	@StateObject var downloadManager = DownloadManager.shared
	@StateObject var fileImportManager = FileImportManager.shared
	
	@State private var _selectedInfoAppPresenting: AnyApp?
	@State private var _selectedSigningAppPresenting: AnyApp?
	@State private var _selectedInstallAppPresenting: AnyApp?
	@State private var _isImportingPresenting = false
	@State private var _isDownloadingPresenting = false
	@State private var _alertDownloadString: String = ""
	
	@State private var _selectedAppUUIDs: Set<String> = []
	@State private var _editMode: EditMode = .inactive
	
	@State private var _searchText = ""
	@State private var _selectedScope: Scope = .all

	
	@Namespace private var _namespace
	
	private func filteredAndSortedApps<T>(from apps: FetchedResults<T>) -> [T] where T: NSManagedObject {
		apps.filter {
			_searchText.isEmpty ||
			(($0.value(forKey: "name") as? String)?.localizedCaseInsensitiveContains(_searchText) ?? false)
		}
	}
	
	private var _filteredSignedApps: [Signed] {
		filteredAndSortedApps(from: _signedApps)
	}
	
	private var _filteredImportedApps: [Imported] {
		filteredAndSortedApps(from: _importedApps)
	}
	
	@FetchRequest(
		entity: Signed.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
		animation: .snappy
	) private var _signedApps: FetchedResults<Signed>
	
	@FetchRequest(
		entity: Imported.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
		animation: .snappy
	) private var _importedApps: FetchedResults<Imported>
	
    var body: some View {
		NavigationView {
			ZStack {
				_mainContent
					.navigationTitle("应用库")
					.navigationBarTitleDisplayMode(.large)
				
				// 文件导入进度显示
				if fileImportManager.isImporting {
					VStack {
						Spacer()
						FileImportProgressView()
							.padding()
					}
				}
			}
				.navigationBarItems(
					leading: EditButton(),
					trailing: Group {
						if _editMode.isEditing {
							Button("删除") {
								_bulkDeleteSelectedApps()
							}
							.disabled(_selectedAppUUIDs.isEmpty)
						} else {
							Menu {
								_importActions()
							} label: {
								Image(systemName: "plus")
							}
						}
					}
				)
		}
			.overlay {
				if
					_filteredSignedApps.isEmpty,
					_filteredImportedApps.isEmpty
				{
					VStack(spacing: 20) {
						Label("无应用", systemImage: "questionmark.app.fill")
							.font(.title2)
							.foregroundColor(.secondary)
						
						Text("通过导入您的第一个IPA文件开始使用。")
							.font(.body)
							.foregroundColor(.secondary)
							.multilineTextAlignment(.center)
						
						Menu {
							_importActions()
						} label: {
							Button("导入") {
								_isImportingPresenting = true
							}
						}
					}
					.padding()
				}
			}
			.environment(\.editMode, $_editMode)
			.sheet(item: $_selectedInfoAppPresenting) { app in
				LibraryInfoView(app: app.base)
			}
			.sheet(item: $_selectedInstallAppPresenting) { app in
				InstallPreviewView(app: app.base, isSharing: app.archive)
			}
			.fullScreenCover(item: $_selectedSigningAppPresenting) { app in
				SigningView(app: app.base)
			}
			.sheet(isPresented: $_isImportingPresenting) {
				MultiFileImporterView(
					allowedContentTypes:  [.ipa, .tipa],
					onDocumentsPicked: { urls in
						guard !urls.isEmpty else { return }
						
						// 使用FileImportManager进行文件导入
						if urls.count == 1 {
							fileImportManager.importFile(urls[0])
						} else {
							fileImportManager.importFiles(urls)
						}
					}
				)
				.ignoresSafeArea()
			}
			.alert("从URL导入", isPresented: $_isDownloadingPresenting) {
				TextField("URL", text: $_alertDownloadString)
					.textInputAutocapitalization(.never)
				Button("取消", role: .cancel) {
					_alertDownloadString = ""
				}
				Button("确定") {
					if let url = URL(string: _alertDownloadString) {
						_ = downloadManager.startDownload(from: url, id: "FeatherManualDownload_\(UUID().uuidString)")
					}
				}
			}
			.onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.installApp"))) { _ in
                if let latest = _signedApps.first {
                    _selectedInstallAppPresenting = AnyApp(base: latest)
                }
			}
			.onChange(of: _editMode) { mode in
				if mode == .inactive {
					_selectedAppUUIDs.removeAll()
				}
			}
        }
    }

extension LibraryView {
	@ViewBuilder
	private func _importActions() -> some View {
		Button("从文件导入", systemImage: "folder") {
			_isImportingPresenting = true
		}
		Button("从URL导入", systemImage: "globe") {
			_isDownloadingPresenting = true
		}
	}
}

extension LibraryView {
	private func _bulkDeleteSelectedApps() {
		let selectedApps = _getAllApps().filter { app in
			guard let uuid = app.uuid else { return false }
			return _selectedAppUUIDs.contains(uuid)
		}
		
		for app in selectedApps {
			Storage.shared.deleteApp(for: app)
		}
		
		_selectedAppUUIDs.removeAll()
		
	}
	
	private func _getAllApps() -> [AppInfoPresentable] {
		var allApps: [AppInfoPresentable] = []
		
		if _selectedScope == .all || _selectedScope == .signed {
			allApps.append(contentsOf: _filteredSignedApps)
		}
		
		if _selectedScope == .all || _selectedScope == .imported {
			allApps.append(contentsOf: _filteredImportedApps)
		}
		
		return allApps
	}
}

extension LibraryView {
	enum Scope: CaseIterable {
		case all
		case signed
		case imported
		
		var displayName: String {
			switch self {
			case .all: return "全部"
			case .signed: return "已签名"
			case .imported: return "已导入"
			}
		}
	}
	
	@ViewBuilder
	private var _mainContent: some View {
		List {
			_appsListContent
		}
		.searchable(text: $_searchText)
	}
	
	@ViewBuilder
	private var _appsListContent: some View {
		if !_filteredSignedApps.isEmpty || !_filteredImportedApps.isEmpty {
			_signedAppsSection
			_importedAppsSection
		}
	}
	
	@ViewBuilder
	private var _signedAppsSection: some View {
		if _selectedScope == .all || _selectedScope == .signed {
			Section(
				header: Text("已签名"),
				footer: Text(_filteredSignedApps.count.description)
			) {
				ForEach(_filteredSignedApps, id: \.uuid) { app in
					LibraryCellView(
						app: app,
						selectedInfoAppPresenting: $_selectedInfoAppPresenting,
						selectedSigningAppPresenting: $_selectedSigningAppPresenting,
						selectedInstallAppPresenting: $_selectedInstallAppPresenting,
						selectedAppUUIDs: $_selectedAppUUIDs
					)
				}
			}
		}
	}
	
	@ViewBuilder
	private var _importedAppsSection: some View {
		if _selectedScope == .all || _selectedScope == .imported {
			Section(
				header: Text("已导入"),
				footer: Text(_filteredImportedApps.count.description)
			) {
				ForEach(_filteredImportedApps, id: \.uuid) { app in
					LibraryCellView(
						app: app,
						selectedInfoAppPresenting: $_selectedInfoAppPresenting,
						selectedSigningAppPresenting: $_selectedSigningAppPresenting,
						selectedInstallAppPresenting: $_selectedInstallAppPresenting,
						selectedAppUUIDs: $_selectedAppUUIDs
					)
				}
			}
		}
	}
}

// MARK: - Multi File Importer
struct MultiFileImporterView: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let onDocumentsPicked: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = iOSCompatibility.shared.createDocumentPicker(for: allowedContentTypes, allowsMultipleSelection: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentsPicked: onDocumentsPicked)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentsPicked: ([URL]) -> Void
        private let logger = Logger(subsystem: "com.feather.multifileimporter", category: "MultiFileImporter")
        
        init(onDocumentsPicked: @escaping ([URL]) -> Void) {
            self.onDocumentsPicked = onDocumentsPicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            logger.info("选择了 \(urls.count) 个文件")
            
            // 使用兼容性工具处理文件权限
            iOSCompatibility.shared.handleFileImportPermissions(for: urls) { [weak self] accessibleUrls in
                guard let self = self else { return }
                
                self.logger.info("成功获取 \(accessibleUrls.count) 个文件的访问权限")
                self.onDocumentsPicked(accessibleUrls)
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            logger.info("用户取消了多文件选择")
            onDocumentsPicked([])
        }
    }
}
