import Foundation

extension FileManager {
    public func createDirectoryIfNeeded(at url: URL) throws {
        if !self.fileExists(atPath: url.path) {
            try self.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    public func removeFileIfNeeded(at url: URL) throws {
        if self.fileExists(atPath: url.path) {
            try self.removeItem(at: url)
        }
    }
    
    public func moveFileIfNeeded(from sourceURL: URL, to destinationURL: URL) throws {
        if !self.fileExists(atPath: destinationURL.path) {
            try self.moveItem(at: sourceURL, to: destinationURL)
        }
    }
    
    static public func forceWrite(content: String, to filename: String) throws {
        let path = URL.documentsDirectory.appendingPathComponent(filename)
        try content.write(to: path, atomically: true, encoding: .utf8)
    }
    
    public func getPath(in directory: URL, for pathExtension: String) -> URL? {
        guard let contents = try? contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return nil
        }
        
        return contents.first(where: { $0.pathExtension == pathExtension })
    }
    
    public func isFileFromFileProvider(at url: URL) -> Bool {
        if let resourceValues = try? url.resourceValues(forKeys: [.isUbiquitousItemKey, .fileResourceIdentifierKey]),
           resourceValues.isUbiquitousItem == true {
            return true
        }
        
        let path = url.path
        if path.contains("/Library/CloudStorage/") || path.contains("/File Provider Storage/") {
            return true
        }
        
        return false
    }
    
    public func decodeAndWrite(base64: String, pathComponent: String) -> URL? {
        let raw = base64.replacingOccurrences(of: " ", with: "+")
        guard let data = Data(base64Encoded: raw) else { return nil }
        let dir = self.temporaryDirectory.appendingPathComponent(UUID().uuidString + pathComponent)
        try? data.write(to: dir)
        return dir
    }
}

extension URL {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}