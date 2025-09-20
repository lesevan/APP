//
//  SigningEntitlementsView.swift
//  Feather
//
//  Created by samara on 20.04.2025.
//

import SwiftUI

// MARK: - View
struct SigningEntitlementsView: View {
	@State private var _isAddingPresenting = false
	
	@Binding var bindingValue: URL?
	
	// MARK: Body
	var body: some View {
		List {
			if let ent = bindingValue {
				Text(ent.lastPathComponent)
					.swipeActions() {
						Button("Delete") {
							FileManager.default.deleteStored(ent) { _ in
								bindingValue = nil
							}
						}
					}
			} else {
				Button("Select entitlements file") {
					_isAddingPresenting = true
				}
			}
		}
		.navigationTitle("Entitlements")
		.sheet(isPresented: $_isAddingPresenting) {
			FileImporterRepresentableView(
				allowedContentTypes:  [.xmlPropertyList, .entitlements],
				onDocumentsPicked: { urls in
					DispatchQueue.main.async { _isAddingPresenting = false }
					guard let selectedFileURL = urls.first else { return }
					print("开始处理权限文件: \(selectedFileURL.lastPathComponent)")
					FileManager.default.moveAndStore(selectedFileURL, with: "FeatherEntitlement") { url in
						DispatchQueue.main.async { 
							bindingValue = url
							print("权限文件导入成功: \(url.lastPathComponent)")
						}
					}
				}
			)
			.ignoresSafeArea()
		}
	}
}
