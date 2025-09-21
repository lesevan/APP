//
//  SigningTweaksView.swift
//  Feather
//
//  Created by samara on 20.04.2025.
//

import SwiftUI

// MARK: - View
struct SigningTweaksView: View {
	@State private var _isAddingPresenting = false
	
	@Binding var options: Options
	
	// MARK: Body
	var body: some View {
		List {
			Section {
				SigningOptionsView.picker(
					"Injection Path",
					systemImage: "doc.badge.gearshape",
					selection: $options.injectPath,
					values: Options.InjectPath.allCases
				)
				SigningOptionsView.picker(
					"Injection Folder",
					systemImage: "folder.badge.gearshape",
					selection: $options.injectFolder,
					values: Options.InjectFolder.allCases
				)
			} header: {
				Text("Injection")
			}
			
			Section {
				if !options.injectionFiles.isEmpty {
					ForEach(options.injectionFiles, id: \.absoluteString) { tweak in
						_file(tweak: tweak)
					}
				} else {
					Text("未选择任何文件")
						.font(.footnote)
						.foregroundColor(.secondary)
				}
			} header: {
				Text("动态库文件")
			} footer: {
				if !options.injectionFiles.isEmpty {
					Text("已选择 \(options.injectionFiles.count) 个文件")
						.font(.caption)
						.foregroundColor(.secondary)
				} else {
					Text("点击右上角的\"添加\"按钮来选择 .dylib 或 .deb 文件")
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
		}
		.navigationTitle("Tweaks")
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					_isAddingPresenting = true
				} label: {
					Text("添加")
				}
			}
		}
		.sheet(isPresented: $_isAddingPresenting) {
			FileImporterRepresentableView(
				allowedContentTypes: [.dylib, .deb],
				allowsMultipleSelection: true,
				onDocumentsPicked: { urls in
					DispatchQueue.main.async { _isAddingPresenting = false }
					
					guard !urls.isEmpty else { return }
					
					for url in urls {
						// 检查文件是否已经存在
						let fileName = url.lastPathComponent
						let alreadyExists = options.injectionFiles.contains { existingURL in
							existingURL.lastPathComponent == fileName
						}
						
						guard !alreadyExists else {
							print("文件已存在，跳过: \(fileName)")
							continue
						}
						
						// 移动并存储文件
						FileManager.default.moveAndStore(url, with: "FeatherTweak") { storedURL in
							DispatchQueue.main.async {
								options.injectionFiles.append(storedURL)
								print("成功添加动态库文件: \(storedURL.lastPathComponent)")
							}
						}
					}
				}
			)
			.ignoresSafeArea()
		}
		.animation(.smooth, value: options.injectionFiles)
	}
}

// MARK: - Extension: View
extension SigningTweaksView {
	@ViewBuilder
	private func _file(tweak: URL) -> some View {
		Label(tweak.lastPathComponent, systemImage: "folder.fill")
			.lineLimit(2)
			.frame(maxWidth: .infinity, alignment: .leading)
			.swipeActions(edge: .trailing, allowsFullSwipe: true) {
				_fileActions(tweak: tweak)
			}
			.contextMenu {
				_fileActions(tweak: tweak)
			}
	}
	
	@ViewBuilder
	private func _fileActions(tweak: URL) -> some View {
		Button(role: .destructive) {
			FileManager.default.deleteStored(tweak) { url in
				if let index = options.injectionFiles.firstIndex(where: { $0 == url }) {
					options.injectionFiles.remove(at: index)
				}
			}
		} label: {
			Label("删除", systemImage: "trash")
		}
	}
}
