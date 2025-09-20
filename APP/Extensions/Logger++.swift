import OSLog

extension Logger {
	@MainActor
	private static var subsystem: String {
		return Bundle.main.bundleIdentifier!
	}
	
	@MainActor
	static let signing = Logger(subsystem: subsystem, category: "Signing")
	
	@MainActor
	static let misc = Logger(subsystem: subsystem, category: "Misc")
}