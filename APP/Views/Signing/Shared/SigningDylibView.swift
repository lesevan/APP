
import SwiftUI
import ZsignSwift

struct SigningDylibView: View {
	@State private var _dylibs: [String] = []
	@State private var _hiddenDylibCount: Int = 0
	
	var app: AppInfoPresentable
	@Binding var options: Options?
	
	var body: some View {
		List {
			Section {
				ForEach(_dylibs, id: \.self) { dylib in
					SigningToggleCellView(
						title: dylib,
						options: $options,
						arrayKeyPath: \.disInjectionFiles
					)
				}
			}
			.disabled(options == nil)
			
			Section("隐藏") {
				Text("\(_hiddenDylibCount)个必需的系统动态库未显示。")
					.font(.footnote)
					.foregroundColor(.secondary)
			}
		}
		.navigationTitle("动态库")
		.onAppear(perform: _loadDylibs)
	}
}

extension SigningDylibView {
	private func _loadDylibs() {
		guard let path = Storage.shared.getAppDirectory(for: app) else { 
			print("无法获取应用目录")
			return 
		}
		
		let bundle = Bundle(url: path)
		guard let executableName = bundle?.exec else {
			print("无法获取可执行文件名")
			return
		}
		
		let execPath = path.appendingPathComponent(executableName).relativePath
		print("正在分析可执行文件: \(execPath)")
		
		let allDylibs = Zsign.listDylibs(appExecutable: execPath).map { $0 as String }
		print("找到 \(allDylibs.count) 个动态库依赖")
		
		_dylibs = allDylibs.filter { $0.hasPrefix("@rpath") || $0.hasPrefix("@executable_path") }
		_hiddenDylibCount = allDylibs.count - _dylibs.count
		
		print("显示 \(_dylibs.count) 个可配置的动态库，隐藏 \(_hiddenDylibCount) 个系统动态库")
	}
}
