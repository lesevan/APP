import Foundation
import UIKit
import os.log

@MainActor
class OptionsManager: ObservableObject {
	static let shared = OptionsManager()
	
	@Published var options: Options
	private let _key = "signing_options"
	private let logger = Logger(subsystem: "com.feather.options", category: "OptionsManager")
	
	init() {
		if
			let data = UserDefaults.standard.data(forKey: _key),
			let savedOptions = try? JSONDecoder().decode(Options.self, from: data)
		{
			self.options = savedOptions
			logger.info("Loaded saved options from UserDefaults")
		} else {
			self.options = Options.defaultOptions
			self.saveOptions()
			logger.info("Using default options")
		}
	}
	
	func saveOptions() {
		do {
			let encoded = try JSONEncoder().encode(options)
			UserDefaults.standard.set(encoded, forKey: _key)
			objectWillChange.send()
			logger.info("Options saved successfully")
		} catch {
			logger.error("Failed to save options: \(error.localizedDescription)")
		}
	}
	
	func resetToDefaults() {
		options = Options.defaultOptions
		saveOptions()
		logger.info("Options reset to defaults")
	}
}

struct Options: Codable, Equatable {
	var appName: String?
	var appVersion: String?
	var appIdentifier: String?
	var appEntitlementsFile: URL?
	var appAppearance: AppAppearance
	var minimumAppRequirement: MinimumAppRequirement
	var signingOption: SigningOption
	var injectPath: InjectPath
	var injectFolder: InjectFolder
	var ppqString: String
	var ppqProtection: Bool
	var dynamicProtection: Bool
	var identifiers: [String: String]
	var displayNames: [String: String]
	var injectionFiles: [URL]
	var disInjectionFiles: [String]
	var removeFiles: [String]
	var fileSharing: Bool
	var itunesFileSharing: Bool
	var proMotion: Bool
	var gameMode: Bool
	var ipadFullscreen: Bool
	var removeURLScheme: Bool
	var removeProvisioning: Bool
	var changeLanguageFilesForCustomDisplayName: Bool
	var experiment_supportLiquidGlass: Bool
	var experiment_replaceSubstrateWithEllekit: Bool
	var post_installAppAfterSigned: Bool
	var post_deleteAppAfterSigned: Bool
	static let defaultOptions = Options(
		appAppearance: .default,
		minimumAppRequirement: .default,
		signingOption: .default,
		injectPath: .executable_path,
		injectFolder: .frameworks,
		ppqString: randomString(),
		ppqProtection: true,
		dynamicProtection: false,
		identifiers: [:],
		displayNames: [:],
		injectionFiles: [],
		disInjectionFiles: [],
		removeFiles: [],
		fileSharing: false,
		itunesFileSharing: false,
		proMotion: false,
		gameMode: false,
		ipadFullscreen: false,
		removeURLScheme: false,
		removeProvisioning: false,
		changeLanguageFilesForCustomDisplayName: false,
		experiment_supportLiquidGlass: false,
		experiment_replaceSubstrateWithEllekit: false,
		post_installAppAfterSigned: false,
		post_deleteAppAfterSigned: false
	)

	enum AppAppearance: String, Codable, CaseIterable, LocalizedDescribable {
		case `default`
		case light = "Light"
		case dark = "Dark"

		var localizedDescription: String {
			switch self {
			case .default: "跟随系统"
			case .light: "浅色"
			case .dark: "深色"
			}
		}
	}

	enum MinimumAppRequirement: String, Codable, CaseIterable, LocalizedDescribable {
		case `default`
		case v16 = "16.0"
		case v15 = "15.0"
		case v14 = "14.0"
		case v13 = "13.0"
		case v12 = "12.0"

		var localizedDescription: String {
			switch self {
			case .default: "默认"
			case .v16: "16.0"
			case .v15: "15.0"
			case .v14: "14.0"
			case .v13: "13.0"
			case .v12: "12.0"
			}
		}
	}
	
	enum SigningOption: String, Codable, CaseIterable, LocalizedDescribable {
		case `default`
		case onlyModify

		var localizedDescription: String {
			switch self {
			case .default: "默认"
			case .onlyModify: "仅修改"
			}
		}
	}
	
	enum InjectPath: String, Codable, CaseIterable, LocalizedDescribable {
		case executable_path = "@executable_path"
		case rpath = "@rpath"
	}
	
	enum InjectFolder: String, Codable, CaseIterable, LocalizedDescribable {
		case root = "/"
		case frameworks = "/Frameworks/"
	}
	
	static func randomString() -> String {
		String((0..<6).compactMap { _ in UUID().uuidString.randomElement() })
	}
}

protocol LocalizedDescribable {
	var localizedDescription: String { get }
}

extension LocalizedDescribable where Self: RawRepresentable, RawValue == String {
	var localizedDescription: String {
		let localized = NSLocalizedString(self.rawValue, comment: "")
		return localized == self.rawValue ? self.rawValue : localized
	}
}
