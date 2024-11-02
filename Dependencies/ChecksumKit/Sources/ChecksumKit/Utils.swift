//
//  Utils.swift
//  ChecksumKit
//
//  Created by Andrii Zinoviev on 02.11.2024.
//

import Foundation

extension Data {
    public var hexString: String {
        self.map { String(format: "%02hhx", $0) }.joined()
    }

    public init?(hexString: String) {
        self.init(capacity: hexString.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: hexString, range: NSRange(hexString.startIndex..., in: hexString)) { match, _, _ in
            let byteString = (hexString as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            self.append(num)
        }
        
        guard self.count > 0 else { return nil }
    }
}

extension FileManager {
    public func isDirectory(url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        self.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
}

extension URL {
    static func closestCommonPath(for urls: [URL]) -> String? {
        guard let firstURL = urls.first else { return nil }
        
        var commonPathComponents = firstURL.standardized.resolvingSymlinksInPath().pathComponents
        
        for url in urls.dropFirst() {
            let pathComponents = url.standardized.resolvingSymlinksInPath().pathComponents
            
            commonPathComponents = zip(commonPathComponents, pathComponents)
                .prefix { $0 == $1 }
                .map(\.0)
            
            if commonPathComponents.isEmpty {
                return nil
            }
        }
        
        return NSString.path(withComponents: commonPathComponents)
    }
    
    func relativePath(to destination: URL) -> String? {
        // Get the standardized paths to remove any redundant components
        let sourceComponents = self.standardized.resolvingSymlinksInPath().pathComponents
        let destinationComponents = destination.standardized.resolvingSymlinksInPath().pathComponents
        
        // Find the common path prefix between the two URLs
        let commonComponents = zip(sourceComponents, destinationComponents)
            .prefix { $0 == $1 }
            .map(\.0)
        
        // Get the unique part of the source path
        let uniqueSourceComponents = sourceComponents.dropFirst(commonComponents.count)
        // Get the unique part of the destination path
        let uniqueDestinationComponents = destinationComponents.dropFirst(commonComponents.count)
        
        // Build the relative path:
        // - Start with ".." for each unique component in the source path (going up directories)
        // - Append the unique part of the destination path
        let upDirectories = Array(repeating: "..", count: uniqueSourceComponents.count)
        let relativePathComponents = upDirectories + uniqueDestinationComponents
        
        // Join the components into a relative path string
        return relativePathComponents.isEmpty ? "." : NSString.path(withComponents: relativePathComponents)
    }
}
