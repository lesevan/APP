import UniformTypeIdentifiers

extension UTType {
	@MainActor
	static var entitlements: UTType = .init(filenameExtension: "entitlements", conformingTo: .data)!
	@MainActor
	static var mobileProvision: UTType = .init(filenameExtension: "mobileprovision", conformingTo: .data)!
	@MainActor
	static var dylib: UTType = .init(filenameExtension: "dylib", conformingTo: .data)!
	@MainActor
	static var deb: UTType = .init(filenameExtension: "deb", conformingTo: .data)!
	@MainActor
	static var p12: UTType = .init(filenameExtension: "p12", conformingTo: .data)!
	@MainActor
	static var ipa: UTType = .init(filenameExtension: "ipa")!
	@MainActor
	static var tipa: UTType = .init(filenameExtension: "tipa")!
}